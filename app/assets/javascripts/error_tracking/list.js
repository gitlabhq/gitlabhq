import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import store from './store';
import ErrorTrackingList from './components/error_tracking_list.vue';

export default () => {
  const selector = '#js-error_tracking';

  const domEl = document.querySelector(selector);
  const {
    indexPath,
    enableErrorTrackingLink,
    illustrationPath,
    projectPath,
    listPath,
  } = domEl.dataset;
  let { errorTrackingEnabled, userCanEnableErrorTracking } = domEl.dataset;

  errorTrackingEnabled = parseBoolean(errorTrackingEnabled);
  userCanEnableErrorTracking = parseBoolean(userCanEnableErrorTracking);

  // eslint-disable-next-line no-new
  new Vue({
    el: selector,
    components: {
      ErrorTrackingList,
    },
    store,
    render(createElement) {
      return createElement('error-tracking-list', {
        props: {
          indexPath,
          enableErrorTrackingLink,
          errorTrackingEnabled,
          illustrationPath,
          userCanEnableErrorTracking,
          projectPath,
          listPath,
        },
      });
    },
  });
};
