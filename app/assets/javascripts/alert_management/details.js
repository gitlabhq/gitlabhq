import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import AlertDetails from './components/alert_details.vue';

Vue.use(VueApollo);

export default selector => {
  const domEl = document.querySelector(selector);
  const { alertId, projectPath, projectIssuesPath } = domEl.dataset;

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

  // eslint-disable-next-line no-new
  new Vue({
    el: selector,
    apolloProvider,
    components: {
      AlertDetails,
    },
    render(createElement) {
      return createElement('alert-details', {
        props: {
          alertId,
          projectPath,
          projectIssuesPath,
        },
      });
    },
  });
};
