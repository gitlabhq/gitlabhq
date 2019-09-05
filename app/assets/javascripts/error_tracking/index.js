import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import store from './store';
import ErrorTrackingList from './components/error_tracking_list.vue';

export default () => {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-error_tracking',
    components: {
      ErrorTrackingList,
    },
    store,
    render(createElement) {
      const domEl = document.querySelector(this.$options.el);
      const { indexPath, enableErrorTrackingLink, illustrationPath } = domEl.dataset;
      let { errorTrackingEnabled, userCanEnableErrorTracking } = domEl.dataset;

      errorTrackingEnabled = parseBoolean(errorTrackingEnabled);
      userCanEnableErrorTracking = parseBoolean(userCanEnableErrorTracking);

      return createElement('error-tracking-list', {
        props: {
          indexPath,
          enableErrorTrackingLink,
          errorTrackingEnabled,
          illustrationPath,
          userCanEnableErrorTracking,
        },
      });
    },
  });
};
