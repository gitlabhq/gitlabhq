import API from '~/api';

import Tracking from './tracking';
import { GITLAB_INTERNAL_EVENT_CATEGORY, SERVICE_PING_SCHEMA } from './constants';

const InternalEvents = {
  /**
   *
   * @param {string} event
   */
  track_event(event) {
    API.trackRedisHllUserEvent(event);
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
};

export default InternalEvents;
