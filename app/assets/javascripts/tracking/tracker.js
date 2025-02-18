import { LOAD_ACTION_ATTR_SELECTOR } from './constants';
import { dispatchSnowplowEvent } from './dispatch_snowplow_event';
import getStandardContext from './get_standard_context';
import {
  getEventHandlers,
  createEventPayload,
  renameKey,
  getReferrersCache,
  addReferrersCacheEntry,
} from './utils';

export const Tracker = {
  nonInitializedQueue: [],
  initialized: false,
  ALLOWED_URL_HASHES: ['#diff', '#note'],
  /**
   * (Legacy) Determines if tracking is enabled at the user level.
   * https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/DNT.
   *
   * @returns {Boolean}
   */
  trackable() {
    return !['1', 'yes'].includes(
      window.doNotTrack || navigator.doNotTrack || navigator.msDoNotTrack,
    );
  },

  /**
   * Determines if Snowplow is available/enabled.
   *
   * @returns {Boolean}
   */
  enabled() {
    return typeof window.snowplow === 'function' && Tracker.trackable();
  },

  /**
   * Dispatches a structured event:
   * https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/
   *
   * If the library is not initialized and events are trying to be
   * dispatched (data-attributes, load-events), they will be added
   * to a queue to be flushed afterwards.
   *
   * If there is an error when using the library, it will return ´false´
   * and ´true´ otherwise.
   *
   * @param  {...any} eventData defined event schema
   * @returns {Boolean}
   */
  event(...eventData) {
    if (!Tracker.enabled()) {
      return false;
    }

    if (!Tracker.initialized) {
      Tracker.nonInitializedQueue.push(eventData);
      return false;
    }

    return dispatchSnowplowEvent(...eventData);
  },

  /**
   * Dispatches any event emitted before initialization.
   *
   * @returns {undefined}
   */
  flushPendingEvents() {
    Tracker.initialized = true;

    while (Tracker.nonInitializedQueue.length) {
      dispatchSnowplowEvent(...Tracker.nonInitializedQueue.shift());
    }
  },

  /**
   * Attaches event handlers for data-attributes powered events.
   *
   * @param {String} category - the default category for all events
   * @param {HTMLElement} parent - element containing data-attributes
   * @returns {Array}
   */
  bindDocument(category = document.body.dataset.page, parent = document) {
    if (!Tracker.enabled() || parent.trackingBound) {
      return [];
    }

    // eslint-disable-next-line no-param-reassign
    parent.trackingBound = true;

    const handlers = getEventHandlers(category, (...args) => Tracker.event(...args));
    handlers.forEach((event) => parent.addEventListener(event.name, event.func));

    return handlers;
  },

  /**
   * Attaches event handlers for load-events (on render).
   *
   * @param {String} category - the default category for all events
   * @param {HTMLElement} parent - element containing event targets
   * @returns {Array}
   */
  trackLoadEvents(category = document.body.dataset.page, parent = document) {
    if (!Tracker.enabled()) {
      return [];
    }

    const loadEvents = parent.querySelectorAll(LOAD_ACTION_ATTR_SELECTOR);

    loadEvents.forEach((element) => {
      const { action, data } = createEventPayload(element);
      Tracker.event(category, action, data);
    });

    return loadEvents;
  },

  /**
   * Enable Snowplow automatic form tracking.
   * The config param requires at least one array of either forms
   * class names, or field name attributes.
   * https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/
   *
   * @param {Object} config
   * @param {Array} contexts
   * @returns {undefined}
   */
  enableFormTracking(config, contexts = []) {
    if (!Tracker.enabled()) {
      return;
    }

    if (!Array.isArray(config?.forms?.allow) && !Array.isArray(config?.fields?.allow)) {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      throw new Error('Unable to enable form event tracking without allow rules.');
    }

    // Ignore default/standard schema
    const standardContext = getStandardContext();
    const userProvidedContexts = contexts.filter(
      (context) => context.schema !== standardContext.schema,
    );

    const mappedConfig = {};
    if (config.forms) {
      mappedConfig.forms = renameKey(config.forms, 'allow', 'allowlist');
    }

    if (config.fields) {
      mappedConfig.fields = renameKey(config.fields, 'allow', 'allowlist');
    }

    const enabler = () =>
      window.snowplow('enableFormTracking', {
        options: mappedConfig,
        context: userProvidedContexts,
      });

    if (document.readyState === 'complete') {
      enabler();
    } else {
      document.addEventListener('readystatechange', () => {
        if (document.readyState === 'complete') {
          enabler();
        }
      });
    }
  },

  /**
   * Replaces the URL and referrer for the default web context
   * if the replacements are available.
   *
   * @returns {undefined}
   */
  setAnonymousUrls() {
    const { snowplowPseudonymizedPageUrl: pageUrl } = window.gl;

    if (!pageUrl) {
      return;
    }

    const referrers = getReferrersCache();
    const pageLinks = Object.seal({
      url: pageUrl,
      referrer: '',
      originalUrl: window.location.href,
    });

    const appendHash = Tracker.ALLOWED_URL_HASHES.some((prefix) =>
      window.location.hash.startsWith(prefix),
    );
    const customUrl = `${pageUrl}${appendHash ? window.location.hash : ''}`;
    window.snowplow('setCustomUrl', customUrl);

    // If Browser SDK is enabled set Custom url and Referrer url
    if (window.glClient) {
      window.glClient?.setCustomUrl(customUrl);
    }
    if (document.referrer) {
      const node = referrers.find((links) => links.originalUrl === document.referrer);

      if (node) {
        pageLinks.referrer = node.url;
        window.snowplow('setReferrerUrl', pageLinks.referrer);

        if (window.glClient) {
          window.glClient?.setReferrerUrl(pageLinks.referrer);
        }
      } else {
        window.snowplow('setReferrerUrl', window.gl?.maskedDefaultReferrerUrl);
      }
    }

    addReferrersCacheEntry(referrers, pageLinks);
  },
};
