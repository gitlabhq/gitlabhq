import { getAllExperimentContexts } from '~/experimentation/utils';
import { DEFAULT_SNOWPLOW_OPTIONS } from './constants';
import getStandardContext from './get_standard_context';
import Tracking from './tracking';
import InternalEvents from './internal_events';

export { Tracking as default };
export { InternalEvents };

/**
 * Tracker initialization as defined in:
 * https://docs.snowplow.io/docs/collecting-data/collecting-from-own-applications/javascript-trackers/javascript-tracker/javascript-tracker-v3/tracker-setup/initialization-options/.
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

  // must be before initializing the trackers
  Tracking.setAnonymousUrls();

  window.snowplow('enableActivityTracking', {
    minimumVisitLength: 30,
    heartbeatDelay: 30,
  });
  // must be after enableActivityTracking
  const standardContext = getStandardContext();
  const experimentContexts = getAllExperimentContexts();
  // To not expose personal identifying information, the page title is hardcoded as `GitLab`
  // See: https://gitlab.com/gitlab-org/gitlab/-/issues/345243
  window.snowplow('trackPageView', {
    title: 'GitLab',
    context: [standardContext, ...experimentContexts],
  });
  window.snowplow('setDocumentTitle', 'GitLab');

  if (window.snowplowOptions.formTracking) {
    Tracking.enableFormTracking(opts.formTrackingConfig);
  }

  if (window.snowplowOptions.linkClickTracking) {
    window.snowplow('enableLinkClickTracking');
  }

  Tracking.flushPendingEvents();

  Tracking.bindDocument();
  Tracking.trackLoadEvents();

  InternalEvents.bindInternalEventDocument();
  InternalEvents.trackInternalLoadEvents();
  InternalEvents.initBrowserSDK();
}
