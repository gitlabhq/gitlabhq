import { Tracker } from 'jh_else_ce/tracking/tracker';
import { addExperimentContext } from './utils';

const Tracking = Object.assign(Tracker, {
  /**
   * Returns an implementation of this class in the form of
   * a Vue mixin.
   *
   * @param {Object} opts - default options for all events
   * @returns {Object}
   */
  mixin(opts = {}) {
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
  },
});

export default Tracking;
