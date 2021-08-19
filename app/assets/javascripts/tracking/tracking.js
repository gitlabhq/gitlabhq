import { LOAD_ACTION_ATTR_SELECTOR, DEPRECATED_LOAD_EVENT_ATTR_SELECTOR } from './constants';
import { dispatchSnowplowEvent } from './dispatch_snowplow_event';
import getStandardContext from './get_standard_context';
import { getEventHandlers, createEventPayload, renameKey, addExperimentContext } from './utils';

export default class Tracking {
  static queuedEvents = [];
  static initialized = false;

  /**
   * (Legacy) Determines if tracking is enabled at the user level.
   * https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/DNT.
   *
   * @returns {Boolean}
   */
  static trackable() {
    return !['1', 'yes'].includes(
      window.doNotTrack || navigator.doNotTrack || navigator.msDoNotTrack,
    );
  }

  /**
   * Determines if Snowplow is available/enabled.
   *
   * @returns {Boolean}
   */
  static enabled() {
    return typeof window.snowplow === 'function' && this.trackable();
  }

  /**
   * Dispatches a structured event per our taxonomy:
   * https://docs.gitlab.com/ee/development/snowplow/index.html#structured-event-taxonomy.
   *
   * If the library is not initialized and events are trying to be
   * dispatched (data-attributes, load-events), they will be added
   * to a queue to be flushed afterwards.
   *
   * @param  {...any} eventData defined event taxonomy
   * @returns {undefined|Boolean}
   */
  static event(...eventData) {
    if (!this.enabled()) {
      return false;
    }

    if (!this.initialized) {
      this.queuedEvents.push(eventData);
      return false;
    }

    return dispatchSnowplowEvent(...eventData);
  }

  /**
   * Dispatches any event emitted before initialization.
   *
   * @returns {undefined}
   */
  static flushPendingEvents() {
    this.initialized = true;

    while (this.queuedEvents.length) {
      dispatchSnowplowEvent(...this.queuedEvents.shift());
    }
  }

  /**
   * Attaches event handlers for data-attributes powered events.
   *
   * @param {String} category - the default category for all events
   * @param {HTMLElement} parent - element containing data-attributes
   * @returns {Array}
   */
  static bindDocument(category = document.body.dataset.page, parent = document) {
    if (!this.enabled() || parent.trackingBound) {
      return [];
    }

    // eslint-disable-next-line no-param-reassign
    parent.trackingBound = true;

    const handlers = getEventHandlers(category, (...args) => this.event(...args));
    handlers.forEach((event) => parent.addEventListener(event.name, event.func));

    return handlers;
  }

  /**
   * Attaches event handlers for load-events (on render).
   *
   * @param {String} category - the default category for all events
   * @param {HTMLElement} parent - element containing event targets
   * @returns {Array}
   */
  static trackLoadEvents(category = document.body.dataset.page, parent = document) {
    if (!this.enabled()) {
      return [];
    }

    const loadEvents = parent.querySelectorAll(
      `${LOAD_ACTION_ATTR_SELECTOR}, ${DEPRECATED_LOAD_EVENT_ATTR_SELECTOR}`,
    );

    loadEvents.forEach((element) => {
      const { action, data } = createEventPayload(element);
      this.event(category, action, data);
    });

    return loadEvents;
  }

  /**
   * Enable Snowplow automatic form tracking.
   * The config param requires at least one array of either forms
   * class names, or field name attributes.
   * https://docs.gitlab.com/ee/development/snowplow/index.html#form-tracking.
   *
   * @param {Object} config
   * @param {Array} contexts
   * @returns {undefined}
   */
  static enableFormTracking(config, contexts = []) {
    if (!this.enabled()) {
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
      mappedConfig.forms = renameKey(config.forms, 'allow', 'whitelist');
    }

    if (config.fields) {
      mappedConfig.fields = renameKey(config.fields, 'allow', 'whitelist');
    }

    const enabler = () => window.snowplow('enableFormTracking', mappedConfig, userProvidedContexts);

    if (document.readyState === 'complete') {
      enabler();
    } else {
      document.addEventListener('readystatechange', () => {
        if (document.readyState === 'complete') {
          enabler();
        }
      });
    }
  }

  /**
   * Returns an implementation of this class in the form of
   * a Vue mixin.
   *
   * @param {Object} opts - default options for all events
   * @returns {Object}
   */
  static mixin(opts = {}) {
    return {
      computed: {
        trackingCategory() {
          const localCategory = this.tracking ? this.tracking.category : null;
          return localCategory || opts.category;
        },
        trackingOptions() {
          const options = addExperimentContext(opts);
          return { ...options, ...this.tracking };
        },
      },
      methods: {
        track(action, data = {}) {
          const category = data.category || this.trackingCategory;
          const options = {
            ...this.trackingOptions,
            ...data,
          };

          Tracking.event(category, action, options);
        },
      },
    };
  }
}
