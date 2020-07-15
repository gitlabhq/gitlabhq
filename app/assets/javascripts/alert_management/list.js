import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import { parseBoolean } from '~/lib/utils/common_utils';
import AlertManagementList from './components/alert_management_list_wrapper.vue';

Vue.use(VueApollo);

export default () => {
  const selector = '#js-alert_management';

  const domEl = document.querySelector(selector);
  const {
    projectPath,
    enableAlertManagementPath,
    emptyAlertSvgPath,
    populatingAlertsHelpUrl,
    opsgenieMvcTargetUrl,
  } = domEl.dataset;
  let { alertManagementEnabled, userCanEnableAlertManagement, opsgenieMvcEnabled } = domEl.dataset;

  alertManagementEnabled = parseBoolean(alertManagementEnabled);
  userCanEnableAlertManagement = parseBoolean(userCanEnableAlertManagement);
  opsgenieMvcEnabled = parseBoolean(opsgenieMvcEnabled);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(
      {},
      {
        cacheConfig: {
          dataIdFromObject: object => {
            // eslint-disable-next-line no-underscore-dangle
            if (object.__typename === 'AlertManagementAlert') {
              return object.iid;
            }
            return defaultDataIdFromObject(object);
          },
        },
      },
    ),
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
          populatingAlertsHelpUrl,
          emptyAlertSvgPath,
          alertManagementEnabled,
          userCanEnableAlertManagement,
          opsgenieMvcTargetUrl,
          opsgenieMvcEnabled,
        },
      });
    },
  });
};
