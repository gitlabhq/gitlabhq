import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import produce from 'immer';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import AlertDetails from './components/alert_details.vue';
import { PAGE_CONFIG } from './constants';
import sidebarStatusQuery from './graphql/queries/alert_sidebar_status.query.graphql';
import createRouter from './router';

Vue.use(VueApollo);

export default (selector) => {
  const domEl = document.querySelector(selector);
  const { alertId, projectPath, projectIssuesPath, projectId, page } = domEl.dataset;
  const router = createRouter();

  const resolvers = {
    Mutation: {
      toggleSidebarStatus: (_, __, { cache }) => {
        const sourceData = cache.readQuery({ query: sidebarStatusQuery });
        const data = produce(sourceData, (draftData) => {
          draftData.sidebarStatus = !draftData.sidebarStatus;
        });
        cache.writeQuery({ query: sidebarStatusQuery, data });
      },
    },
  };

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
      assumeImmutableResults: true,
    }),
  });

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: sidebarStatusQuery,
    data: {
      sidebarStatus: false,
    },
  });

  const provide = {
    projectPath,
    alertId,
    page,
    projectIssuesPath,
    projectId,
    statuses: PAGE_CONFIG[page].STATUSES,
  };

  if (page === PAGE_CONFIG.OPERATIONS.TITLE) {
    const { TRACK_ALERTS_DETAILS_VIEWS_OPTIONS, TRACK_ALERT_STATUS_UPDATE_OPTIONS } = PAGE_CONFIG[
      page
    ];
    provide.trackAlertsDetailsViewsOptions = TRACK_ALERTS_DETAILS_VIEWS_OPTIONS;
    provide.trackAlertStatusUpdateOptions = TRACK_ALERT_STATUS_UPDATE_OPTIONS;
  } else if (page === PAGE_CONFIG.THREAT_MONITORING.TITLE) {
    provide.isThreatMonitoringPage = true;
  }

  // eslint-disable-next-line no-new
  new Vue({
    el: selector,
    components: {
      AlertDetails,
    },
    provide,
    apolloProvider,
    router,
    render(createElement) {
      return createElement('alert-details', {});
    },
  });
};
