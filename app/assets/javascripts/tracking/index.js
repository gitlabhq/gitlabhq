import { DEFAULT_SNOWPLOW_OPTIONS } from './constants';
import getStandardContext from './get_standard_context';
import Tracking from './tracking';

export { Tracking as default };

/**
 * Tracker initialization as defined in:
 * https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/javascript-trackers/javascript-tracker/javascript-tracker-v2/tracker-setup/initializing-a-tracker-2/.
 * It also dispatches any event emitted before its execution.
 *
 * @returns {undefined}
 */
export function initUserTracking() {
  if (!Tracking.enabled()) {
    return;
  }

  const opts = { ...DEFAULT_SNOWPLOW_OPTIONS, ...window.snowplowOptions };
  window.snowplow('newTracker', opts.namespace, opts.hostname, opts);

  document.dispatchEvent(new Event('SnowplowInitialized'));
  Tracking.flushPendingEvents();
}

/**
 * Enables tracking of built-in events: page views, page pings.
 * Optionally enables form and link tracking (automatically).
 * Attaches event handlers for data-attributes powered events, and
 * load-events (on render).
 *
 * @returns {undefined}
 */
export function initDefaultTrackers() {
  if (!Tracking.enabled()) {
    return;
  }

  const opts = { ...DEFAULT_SNOWPLOW_OPTIONS, ...window.snowplowOptions };

  window.snowplow('enableActivityTracking', 30, 30);
  // must be after enableActivityTracking
  const standardContext = getStandardContext();
  window.snowplow('trackPageView', null, [standardContext]);

  if (window.snowplowOptions.formTracking) {
    Tracking.enableFormTracking(opts.formTrackingConfig);
  }

  if (window.snowplowOptions.linkClickTracking) {
    window.snowplow('enableLinkClickTracking');
  }

  Tracking.bindDocument();
  Tracking.trackLoadEvents();
}
