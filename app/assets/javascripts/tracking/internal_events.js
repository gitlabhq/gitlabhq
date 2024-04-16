import API from '~/api';

import Tracking from './tracking';
import { LOAD_INTERNAL_EVENTS_SELECTOR, SERVICE_PING_SCHEMA } from './constants';
import { Tracker } from './tracker';
import {
  InternalEventHandler,
  createInternalEventPayload,
  validateAdditionalProperties,
} from './utils';

const InternalEvents = {
  /**
   *
   * @param {string} event
   * @param {Object} additionalProperties - Object containing additional data for the event tracking.
   * Supports `value`(number), `property`(string), and `label`(string) as keys.
   * @param {string} category - The category of the event. This is optional and
   * defaults to the page name where the event was triggered. It's advised not to use
   * this parameter for new events unless absolutely necessary.
   *
   */
  trackEvent(event, additionalProperties = {}, category = undefined) {
    validateAdditionalProperties(additionalProperties);

    API.trackInternalEvent(event, additionalProperties);
    Tracking.event(category, event, {
      context: {
        schema: SERVICE_PING_SCHEMA,
        data: {
          event_name: event,
          data_source: 'redis_hll',
        },
      },
      ...additionalProperties,
    });
    this.trackBrowserSDK(event, additionalProperties);
  },
  /**
   * Returns an implementation of this class in the form of
   * a Vue mixin.
   */
  mixin() {
    return {
      methods: {
        trackEvent(event, additionalProperties = {}, category = undefined) {
          InternalEvents.trackEvent(event, additionalProperties, category);
        },
      },
    };
  },
  /**
   * Attaches event handlers for data-attributes powered events.
   *
   * @param {HTMLElement} parent - element containing data-attributes
   * @returns {Object} handler - object containing name of the event and its corresponding function
   */
  bindInternalEventDocument(parent = document) {
    if (!Tracker.enabled() || parent.internalEventsTrackingBound) {
      return [];
    }

    // eslint-disable-next-line no-param-reassign
    parent.internalEventsTrackingBound = true;

    const handler = {
      name: 'click',
      func: (e) => InternalEventHandler(e, this.trackEvent.bind(this)),
    };
    parent.addEventListener(handler.name, handler.func);
    return handler;
  },
  /**
   * Attaches internal event handlers for load events.
   * @param {HTMLElement} parent - element containing event targets
   * @returns {Array}
   */
  trackInternalLoadEvents(parent = document) {
    if (!Tracker.enabled()) {
      return [];
    }

    const loadEvents = parent.querySelectorAll(LOAD_INTERNAL_EVENTS_SELECTOR);

    loadEvents.forEach((element) => {
      const { event, additionalProperties = {} } = createInternalEventPayload(element);
      if (event) {
        this.trackEvent(event, additionalProperties);
      }
    });

    return loadEvents;
  },
  /**
   * Initialize browser sdk for product analytics
   */
  initBrowserSDK() {
    if (window.glClient) {
      window.glClient.setDocumentTitle('GitLab');
      window.glClient.page({
        title: 'GitLab',
      });
    }
  },
  /**
   * track events for Product Analytics
   * @param {string} event
   * @param {Object} additionalProperties - Object containing additional data for the event tracking.
   * Supports `value`(number), `property`(string), and `label`(string) as keys.
   *
   */
  trackBrowserSDK(event, additionalProperties = {}) {
    if (!Tracker.enabled()) {
      return;
    }

    window.glClient?.track(event, additionalProperties);
  },
};

export default InternalEvents;
