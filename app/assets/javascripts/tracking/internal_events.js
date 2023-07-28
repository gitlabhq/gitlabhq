import API from '~/api';

import Tracking from './tracking';
import { GITLAB_INTERNAL_EVENT_CATEGORY, SERVICE_PING_SCHEMA } from './constants';
import { Tracker } from './tracker';
import { InternalEventHandler } from './utils';

const InternalEvents = {
  /**
   *
   * @param {string} event
   */
  track_event(event) {
    API.trackInternalEvent(event);
    Tracking.event(GITLAB_INTERNAL_EVENT_CATEGORY, event, {
      context: {
        schema: SERVICE_PING_SCHEMA,
        data: {
          event_name: event,
          data_source: 'redis_hll',
        },
      },
    });
  },
  /**
   * Returns an implementation of this class in the form of
   * a Vue mixin.
   */
  mixin() {
    return {
      methods: {
        track_event(event) {
          InternalEvents.track_event(event);
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

    const handler = { name: 'click', func: (e) => InternalEventHandler(e, this.track_event) };
    parent.addEventListener(handler.name, handler.func);
    return handler;
  },
};

export default InternalEvents;
