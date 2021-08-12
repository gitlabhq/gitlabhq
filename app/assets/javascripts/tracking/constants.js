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

export const ACTION_ATTR_SELECTOR = '[data-track-action]';
export const LOAD_ACTION_ATTR_SELECTOR = '[data-track-action="render"]';

export const DEPRECATED_EVENT_ATTR_SELECTOR = '[data-track-event]';
export const DEPRECATED_LOAD_EVENT_ATTR_SELECTOR = '[data-track-event="render"]';
