import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ErrorTrackingList from './components/error_tracking_list.vue';
import store from './store';

export default () => {
  const selector = '#js-error_tracking';

  const domEl = document.querySelector(selector);
  const { indexPath, enableErrorTrackingLink, illustrationPath, projectPath, listPath } =
    domEl.dataset;
  let {
    errorTrackingEnabled,
    userCanEnableErrorTracking,
    showIntegratedTrackingDisabledAlert,
    integratedErrorTrackingEnabled,
  } = domEl.dataset;

  errorTrackingEnabled = parseBoolean(errorTrackingEnabled);
  userCanEnableErrorTracking = parseBoolean(userCanEnableErrorTracking);
  integratedErrorTrackingEnabled = parseBoolean(integratedErrorTrackingEnabled);
  showIntegratedTrackingDisabledAlert = parseBoolean(showIntegratedTrackingDisabledAlert);

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
          showIntegratedTrackingDisabledAlert,
          integratedErrorTrackingEnabled,
        },
      });
    },
  });
};
