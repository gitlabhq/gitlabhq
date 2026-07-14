import { defaultDataIdFromObject } from '@apollo/client/core';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { pinia } from '~/pinia/instance';
import service from './service';
import AlertDetails from './components/alert_details.vue';
import { PAGE_CONFIG } from './constants';
import createRouter from './router';

Vue.use(VueApollo);

export default (selector) => {
  const domEl = document.querySelector(selector);
  const {
    alertId,
    projectPath,
    projectIssuesPath,
    projectAlertManagementDetailsPath,
    projectId,
    page,
    canUpdate,
  } = domEl.dataset;
  const iid = alertId;
  const router = createRouter(projectAlertManagementDetailsPath);
  const resolvers = {};

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers, {
      cacheConfig: {
        dataIdFromObject: (object) => {
          // eslint-disable-next-line no-underscore-dangle
          if (object.__typename === 'AlertManagementAlert') {
            return object.iid;
          }
          return defaultDataIdFromObject(object);
        },
      },
    }),
  });

  const provide = {
    projectPath,
    alertId,
    page,
    projectIssuesPath,
    projectId,
    iid,
    statuses: PAGE_CONFIG[page].STATUSES,
    canUpdate: parseBoolean(canUpdate),
    metricImagesService: service,
  };

  const { TRACK_ALERTS_DETAILS_VIEWS_OPTIONS, TRACK_ALERT_STATUS_UPDATE_OPTIONS } =
    PAGE_CONFIG[page];
  provide.trackAlertsDetailsViewsOptions = TRACK_ALERTS_DETAILS_VIEWS_OPTIONS;
  provide.trackAlertStatusUpdateOptions = TRACK_ALERT_STATUS_UPDATE_OPTIONS;

  // eslint-disable-next-line no-new
  new Vue({
    el: selector,
    name: 'AlertDetailsRoot',
    components: {
      AlertDetails,
    },
    pinia,
    provide,
    apolloProvider,
    router,
    render(createElement) {
      return createElement('alert-details', {});
    },
  });
};
