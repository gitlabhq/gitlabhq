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
          // TODO: refactor to remove potentially undefined property
          // https://gitlab.com/gitlab-org/gitlab/-/issues/432995
          const localCategory = 'tracking' in this ? this.tracking.category : null;
          return localCategory || opts.category;
        },
        trackingOptions() {
          // TODO: refactor to remove potentially undefined property
          // https://gitlab.com/gitlab-org/gitlab/-/issues/432995
          const tracking = 'tracking' in this ? this.tracking : {};
          const options = addExperimentContext({ ...opts, ...tracking });

          return options;
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
