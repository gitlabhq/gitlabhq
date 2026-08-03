import { parseBoolean } from '~/lib/utils/common_utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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

  initVueApp({
    el: selector,
    name: 'ErrorTrackingListRoot',
    store,
    component: ErrorTrackingList,
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
};
