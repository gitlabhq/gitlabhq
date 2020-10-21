import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import produce from 'immer';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import AlertDetails from './components/alert_details.vue';
import sidebarStatusQuery from './graphql/queries/sidebar_status.query.graphql';
import createRouter from './router';

Vue.use(VueApollo);

export default selector => {
  const domEl = document.querySelector(selector);
  const { alertId, projectPath, projectIssuesPath, projectId } = domEl.dataset;
  const router = createRouter();

  const resolvers = {
    Mutation: {
      toggleSidebarStatus: (_, __, { cache }) => {
        const sourceData = cache.readQuery({ query: sidebarStatusQuery });
        const data = produce(sourceData, draftData => {
          // eslint-disable-next-line no-param-reassign
          draftData.sidebarStatus = !draftData.sidebarStatus;
        });
        cache.writeQuery({ query: sidebarStatusQuery, data });
      },
    },
  };

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers, {
      cacheConfig: {
        dataIdFromObject: object => {
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

  apolloProvider.clients.defaultClient.cache.writeData({
    data: {
      sidebarStatus: false,
    },
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: selector,
    provide: {
      projectPath,
      alertId,
      projectIssuesPath,
      projectId,
    },
    apolloProvider,
    components: {
      AlertDetails,
    },
    router,
    render(createElement) {
      return createElement('alert-details', {});
    },
  });
};
