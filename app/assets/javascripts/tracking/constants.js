export const SNOWPLOW_JS_SOURCE = 'gitlab-javascript';

export const DEFAULT_SNOWPLOW_OPTIONS = {
  namespace: 'gl',
  hostname: window.location.hostname,
  cookieDomain: window.location.hostname,
  appId: '',
  userFingerprint: false,
  respectDoNotTrack: true,
  forceSecureTracker: true,
  eventMethod: 'post',
  contexts: { webPage: true, performanceTiming: true },
  formTracking: false,
  linkClickTracking: false,
  pageUnloadTimer: 10,
  formTrackingConfig: {
    forms: { allow: [] },
    fields: { allow: [] },
  },
};
