import {
  newTracker,
  enableActivityTracking,
  trackPageView,
  setDocumentTitle,
  trackStructEvent,
  setCustomUrl,
  setReferrerUrl,
} from '@snowplow/browser-tracker';
import {
  enableLinkClickTracking,
  LinkClickTrackingPlugin,
} from '@snowplow/browser-plugin-link-click-tracking';
import { enableFormTracking, FormTrackingPlugin } from '@snowplow/browser-plugin-form-tracking';
import { TimezonePlugin } from '@snowplow/browser-plugin-timezone';
import { GaCookiesPlugin } from '@snowplow/browser-plugin-ga-cookies';
import { PerformanceTimingPlugin } from '@snowplow/browser-plugin-performance-timing';
import { ClientHintsPlugin } from '@snowplow/browser-plugin-client-hints';

const SNOWPLOW_ACTIONS = {
  newTracker,
  enableActivityTracking,
  trackPageView,
  setDocumentTitle,
  trackStructEvent,
  enableLinkClickTracking,
  enableFormTracking,
  setCustomUrl,
  setReferrerUrl,
};

window.snowplow = (action, ...config) => {
  if (SNOWPLOW_ACTIONS[action]) {
    SNOWPLOW_ACTIONS[action](...config);
  } else {
    // eslint-disable-next-line no-console, @gitlab/require-i18n-strings
    console.warn('Unsupported snowplow action:', action);
  }
};

window.snowplowPlugins = [
  LinkClickTrackingPlugin(),
  FormTrackingPlugin(),
  TimezonePlugin(),
  GaCookiesPlugin({
    ga4: true,
    ga4MeasurementId: window.gl?.ga4MeasurementId,
  }),
  PerformanceTimingPlugin(),
  ClientHintsPlugin(),
];

export default {};
