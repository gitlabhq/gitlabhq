import { defaultDataIdFromObject } from '@apollo/client/core';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { PAGE_CONFIG } from '~/vue_shared/alert_details/constants';
import AlertManagementList from './components/alert_management_list_wrapper.vue';
import alertsHelpUrlQuery from './graphql/queries/alert_help_url.query.graphql';

Vue.use(VueApollo);

export default () => {
  const selector = '#js-alert_management';

  const domEl = document.querySelector(selector);
  const {
    projectPath,
    enableAlertManagementPath,
    emptyAlertSvgPath,
    populatingAlertsHelpUrl,
    alertsHelpUrl,
    textQuery,
    assigneeUsernameQuery,
    alertManagementEnabled,
    userCanEnableAlertManagement,
  } = domEl.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(
      {},
      {
        cacheConfig: {
          dataIdFromObject: (object) => {
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

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: alertsHelpUrlQuery,
    data: {
      alertsHelpUrl,
    },
  });

  return new Vue({
    el: selector,
    components: {
      AlertManagementList,
    },
    provide: {
      projectPath,
      textQuery,
      assigneeUsernameQuery,
      enableAlertManagementPath,
      populatingAlertsHelpUrl,
      emptyAlertSvgPath,
      alertManagementEnabled: parseBoolean(alertManagementEnabled),
      trackAlertStatusUpdateOptions: PAGE_CONFIG.OPERATIONS.TRACK_ALERT_STATUS_UPDATE_OPTIONS,
      userCanEnableAlertManagement: parseBoolean(userCanEnableAlertManagement),
    },
    apolloProvider,
    render(createElement) {
      return createElement('alert-management-list');
    },
  });
};
