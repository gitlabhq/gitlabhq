export const SNOWPLOW_JS_SOURCE = 'gitlab-javascript';

export const MAX_LOCAL_STORAGE_QUEUE_SIZE = 100;

export const DEFAULT_SNOWPLOW_OPTIONS = {
  namespace: 'gl',
  hostname: window.location.hostname,
  cookieDomain: window.location.hostname,
  appId: '',
  respectDoNotTrack: true,
  eventMethod: 'post',
  contexts: { webPage: true, performanceTiming: true },
  formTracking: false,
  linkClickTracking: false,
  plugins: window.snowplowPlugins || [],
  formTrackingConfig: {
    forms: { allow: [] },
    fields: { allow: [] },
  },
  maxLocalStorageQueueSize: MAX_LOCAL_STORAGE_QUEUE_SIZE,
};

export const ACTION_ATTR_SELECTOR = '[data-track-action]';
export const LOAD_ACTION_ATTR_SELECTOR = '[data-track-action="render"]';
// Keep these in sync with the strings used in spec/support/matchers/internal_events_matchers.rb
export const INTERNAL_EVENTS_SELECTOR = '[data-event-tracking]';
export const LOAD_INTERNAL_EVENTS_SELECTOR = '[data-event-tracking-load="true"]';

export const URLS_CACHE_STORAGE_KEY = 'gl-snowplow-pseudonymized-urls';

export const REFERRER_TTL = 24 * 60 * 60 * 1000;

export const GOOGLE_ANALYTICS_ID_COOKIE_NAME = '_ga';

export const SERVICE_PING_SCHEMA = 'iglu:com.gitlab/gitlab_service_ping/jsonschema/1-0-1';

export const BASE_ADDITIONAL_PROPERTIES = {
  label: ['string'],
  property: ['string'],
  value: ['number'],
};

// events constants
export const SERVICE_PING_SECURITY_CONFIGURATION_THREAT_MANAGEMENT_VISIT =
  'users_visiting_security_configuration_threat_management';

export const SERVICE_PING_PIPELINE_SECURITY_VISIT = 'users_visiting_pipeline_security';

export const FIND_FILE_BUTTON_CLICK = 'click_find_file_button_on_repository_pages';
export const FIND_FILE_SHORTCUT_CLICK = 'click_go_to_file_shortcut';

export const REF_SELECTOR_CLICK = 'click_ref_selector_on_blob_page';
