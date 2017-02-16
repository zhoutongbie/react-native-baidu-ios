//
//  BBB.m
//  BBB
//
//  Created by zhoutong on 2017/2/16.
//  Copyright © 2017年 zhoutong. All rights reserved.
//

//#import "BBB.h"
//
//@implementation BBB
//RCT_EXPORT_MODULE(BBB);
//
//RCT_EXPORT_METHOD(testPrint:(NSString *)name info:(NSDictionary *)info) {
//    RCTLogInfo(@"%@: %@", name, info);
//    //aaa
//}
//
//@end



#import "BBB.h"
#import "RCTEventDispatcher.h"
#import <BaiduMapAPI_Location/BMKLocationComponent.h>
#import <BaiduMapAPI_Search/BMKSearchComponent.h>
static NSString * const DidStopLocatingUser = @"DidStopLocatingUser";
static NSString * const DidUpdateBMKUserLocation = @"DidUpdateBMKUserLocation";
static NSString * const DidFailToLocateUserWithError = @"DidFailToLocateUserWithError";
static BBB *_instance = nil;


@interface BBB()<BMKLocationServiceDelegate,BMKGeoCodeSearchDelegate>
{
    
}
@property(nonatomic,strong)BMKLocationService *locationService;
@property(nonatomic,strong)BMKGeoCodeSearch *geocodeSearch;
@property(nonatomic,strong)RCTPromiseResolveBlock resove_self;
@property(nonatomic,strong)RCTPromiseRejectBlock reject_self;
@end






@implementation BBB
@synthesize bridge = _bridge;
RCT_EXPORT_MODULE(BBB)

+ (instancetype)sharedInstance {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(_instance == nil) {
            
            _instance = [[self alloc] init];
            _instance.locationService=[[BMKLocationService alloc]init];
            _instance.locationService.delegate=_instance;
            _instance.geocodeSearch=[[BMKGeoCodeSearch alloc]init];
            _instance.geocodeSearch.delegate=_instance;
            
        }
    });
    return _instance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(_instance == nil) {
            _instance = [super allocWithZone:zone];
            _instance.locationService=[[BMKLocationService alloc]init];
            _instance.locationService.delegate=_instance;
        }
    });
    return _instance;
}
+ (dispatch_queue_t)sharedMethodQueue {
    static dispatch_queue_t methodQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        methodQueue = dispatch_queue_create("com.baj.baidulocation", DISPATCH_QUEUE_SERIAL);
    });
    return methodQueue;
    
}

- (dispatch_queue_t)methodQueue {
    return [BBB sharedMethodQueue];
}
- (NSDictionary<NSString *, id> *)constantsToExport {
    return @{
             DidStopLocatingUser: DidStopLocatingUser,
             DidUpdateBMKUserLocation: DidUpdateBMKUserLocation,
             DidFailToLocateUserWithError: DidFailToLocateUserWithError,
             };
}
RCT_EXPORT_METHOD(testPrint:(NSString *)name info:(NSDictionary *)info) {
    RCTLogInfo(@"%@: %@", name, info);
    //aaa
}
RCT_REMAP_METHOD(startLocation,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    
    self.resove_self = resolve;
    self.reject_self = reject;
    
    
    BBB *location = [BBB sharedInstance];
    location.locationService.distanceFilter=5;
    location.locationService.desiredAccuracy=kCLLocationAccuracyBest;
    location.locationService.pausesLocationUpdatesAutomatically=YES;
    location.locationService.allowsBackgroundLocationUpdates=false;
    if(!location.geocodeSearch){
        location.geocodeSearch=[[BMKGeoCodeSearch alloc]init];
        location.geocodeSearch.delegate=location;
    }
    [location.locationService startUserLocationService];
    
    NSLog(@"开始定位：%@",@"");
    
}

RCT_EXPORT_METHOD(stopLocation){
    BBB *location = [BBB sharedInstance];
    [location.locationService stopUserLocationService];
    NSLog(@"结束定位：%@",@"");
}




RCT_EXPORT_METHOD(setDistanceFilter:(NSNumber *)distanceFilter){
    BBB *location = [BBB sharedInstance];
    location.locationService.distanceFilter=[distanceFilter doubleValue];
}
RCT_EXPORT_METHOD(setDesiredAccuracy:(NSNumber *)desiredAccuracy){
    BBB *location = [BBB sharedInstance];
    location.locationService.desiredAccuracy=[desiredAccuracy doubleValue];
}
RCT_EXPORT_METHOD(setHeadingFilter:(NSNumber *)headingFilter){
    BBB *location = [BBB sharedInstance];
    location.locationService.headingFilter=[headingFilter doubleValue];
}
RCT_EXPORT_METHOD(setPausesLocationUpdatesAutomatically:(BOOL)canPause){
    BBB *location = [BBB sharedInstance];
    location.locationService.pausesLocationUpdatesAutomatically=canPause;
}
RCT_EXPORT_METHOD(setAllowsBackgroundLocationUpdates:(BOOL)isAllows){
    BBB *location = [BBB sharedInstance];
    location.locationService.allowsBackgroundLocationUpdates=isAllows;
}
- (void)willStartLocatingUser{
    NSLog(@"willStartLocatingUser：%@",@"");
}

/**
 *在停止定位后，会调用此函数
 */
-(void)didStopLocatingUser{
    NSLog(@"停止定位：%@",@"");
    [self.bridge.eventDispatcher sendAppEventWithName:DidStopLocatingUser body:@{@"message":@"停止定位"}];
}
/**
 *用户位置更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
-(void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation{
    BMKReverseGeoCodeOption *reverseGeocodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];//初始化反编码请求
    reverseGeocodeSearchOption.reverseGeoPoint = userLocation.location.coordinate;//设置反编码
    BOOL flag = [self.geocodeSearch reverseGeoCode:reverseGeocodeSearchOption];//发送反编码请求.并返回是否成功
    if(!flag)
    {
        [self.bridge.eventDispatcher sendAppEventWithName:DidFailToLocateUserWithError body:@{@"code:":@(-1),@"message":@"位置反解析失败"}];
    }
    
    
}

/**
 *定位失败后，会调用此函数
 *@param error 错误号
 */
-(void)didFailToLocateUserWithError:(NSError *)error{
    NSLog(@"定位失败：%@",error);
    [self.bridge.eventDispatcher sendAppEventWithName:DidFailToLocateUserWithError body:@{@"code:":@(error.code),@"message":error.domain}];
}

-(void) onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    if (error == 0) {
        
        NSDictionary *dic =@{@"latitude":@(result.location.latitude),
                             @"longitude":@(result.location.longitude),
                             @"address":result.address,
                             @"locationDescribe":result.address,
                             @"province":result.addressDetail.province,
                             @"city":result.addressDetail.city,
                             @"district":result.addressDetail.district,
                             @"streetName":result.addressDetail.streetName,
                             @"streetNumber":result.addressDetail.streetNumber,
                             };
        NSLog(@"位置更新：%@",dic);
        
        //        [self.bridge.eventDispatcher sendAppEventWithName:DidUpdateBMKUserLocation body:dic];
        self.resove_self(dic);
        
    }else{
        //        [self.bridge.eventDispatcher sendAppEventWithName:DidFailToLocateUserWithError body:@{@"code:":@(error),@"message":@"位置反解析失败"}];
        self.reject_self(@"-1001", @"位置反解析失败", nil);
    }
}


@end

