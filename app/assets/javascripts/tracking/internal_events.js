import API from '~/api';

import Tracking from './tracking';
import { GITLAB_INTERNAL_EVENT_CATEGORY, SERVICE_PING_SCHEMA } from './constants';

const InternalEvents = {
  /**
   * Returns an implementation of this class in the form of
   * a Vue mixin.
   *
   * @param {Object} opts - default options for all events
   * @returns {Object}
   */
  mixin(opts = {}) {
    return {
      mixins: [Tracking.mixin(opts)],
      methods: {
        track_event(event) {
          API.trackRedisHllUserEvent(event);
          this.track(event, {
            context: {
              schema: SERVICE_PING_SCHEMA,
              data: {
                event_name: event,
                data_source: 'redis_hll',
              },
            },
            category: GITLAB_INTERNAL_EVENT_CATEGORY,
          });
        },
      },
    };
  },
};

export default InternalEvents;
