import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import AlertManagementList from './components/alert_management_list.vue';

Vue.use(VueApollo);

export default () => {
  const selector = '#js-alert_management';

  const domEl = document.querySelector(selector);
  const { projectPath, enableAlertManagementPath, emptyAlertSvgPath } = domEl.dataset;
  let { alertManagementEnabled, userCanEnableAlertManagement } = domEl.dataset;

  alertManagementEnabled = parseBoolean(alertManagementEnabled);
  userCanEnableAlertManagement = parseBoolean(userCanEnableAlertManagement);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el: selector,
    apolloProvider,
    components: {
      AlertManagementList,
    },
    render(createElement) {
      return createElement('alert-management-list', {
        props: {
          projectPath,
          enableAlertManagementPath,
          emptyAlertSvgPath,
          alertManagementEnabled,
          userCanEnableAlertManagement,
        },
      });
    },
  });
};
