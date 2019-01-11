import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import store from './store';
import ErrorTrackingList from './components/error_tracking_list.vue';

export default () => {
  if (!gon.features.errorTracking) {
    return;
  }

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
      let { errorTrackingEnabled } = domEl.dataset;

      errorTrackingEnabled = parseBoolean(errorTrackingEnabled);

      return createElement('error-tracking-list', {
        props: {
          indexPath,
          enableErrorTrackingLink,
          errorTrackingEnabled,
          illustrationPath,
        },
      });
    },
  });
};
