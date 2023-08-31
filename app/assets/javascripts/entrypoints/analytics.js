import { glClientSDK } from '@gitlab/application-sdk-browser';

const { analytics_id: appId, analytics_url: host } = window.gon;

if (appId && host) {
  window.glClient = glClientSDK({
    appId,
    host,
    plugins: {
      clientHints: false,
      linkTracking: false,
      performanceTiming: false,
      errorTracking: false,
    },
  });
}
