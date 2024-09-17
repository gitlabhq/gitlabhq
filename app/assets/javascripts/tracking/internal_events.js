import API from '~/api';

import Tracking from './tracking';
import { LOAD_INTERNAL_EVENTS_SELECTOR, SERVICE_PING_SCHEMA } from './constants';
import { Tracker } from './tracker';
import {
  InternalEventHandler,
  createInternalEventPayload,
  validateAdditionalProperties,
  getBaseAdditionalProperties,
  getCustomAdditionalProperties,
} from './utils';

const elementsWithBinding = new WeakMap();

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

    const baseProperties = getBaseAdditionalProperties(additionalProperties);
    const extra = getCustomAdditionalProperties(additionalProperties);

    const properties = {
      ...baseProperties,
      ...(Object.keys(extra).length > 0 && { extra }),
    };

    API.trackInternalEvent(event, additionalProperties);
    Tracking.event(category, event, {
      context: {
        schema: SERVICE_PING_SCHEMA,
        data: {
          event_name: event,
          data_source: 'redis_hll',
        },
      },
      ...properties,
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
   * @param {HTMLElement} parent - element containing data-attributes to which the event listener
   * will be attached.
   * @returns {Function|null} A dispose function that can be called to remove the event listener and
   * unmark the element, or null if no event handler was attached.
   */
  bindInternalEventDocument(parent = document) {
    if (!Tracker.enabled() || elementsWithBinding.has(parent)) {
      return null;
    }

    elementsWithBinding.set(parent, true);

    const eventName = 'click';
    const eventFunc = (e) => InternalEventHandler(e, this.trackEvent.bind(this));

    parent.addEventListener(eventName, eventFunc);

    const dispose = () => {
      elementsWithBinding.delete(parent);

      parent.removeEventListener(eventName, eventFunc);
    };

    return dispose;
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

    const { data = {} } = { ...window.gl?.snowplowStandardContext };

    const trackedAttributes = {
      project_id: data?.project_id,
      namespace_id: data?.namespace_id,
      ...additionalProperties,
    };

    window.glClient?.track(event, trackedAttributes);
  },
};

export default InternalEvents;
