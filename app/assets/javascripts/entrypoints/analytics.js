import { glClientSDK } from '@gitlab/application-sdk-browser';

const { analytics_id: appId, analytics_url: host } = window.gon;

if (appId && host) {
  window.glClient = glClientSDK({
    appId,
    host,
    hasCookieConsent: true,
    plugins: {
      clientHints: false,
      linkTracking: false,
      performanceTiming: false,
      errorTracking: false,
    },
  });

  const userId = window.gl?.snowplowStandardContext?.data?.user_id;

  if (userId) {
    window.glClient?.identify(userId);
  }
}
