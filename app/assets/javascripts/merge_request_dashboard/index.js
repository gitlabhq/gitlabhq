import { concatPagination } from '@apollo/client/utilities';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import App from './components/app.vue';

export function initMergeRequestDashboard(el) {
  Vue.use(VueApollo);

  const { lists, switch_dashboard_path: switchDashboardPath } = JSON.parse(el.dataset.initialData);

  return new Vue({
    el,
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(
        {},
        {
          cacheConfig: {
            typePolicies: {
              CurrentUser: {
                merge: true,
                fields: {
                  reviewRequestedMergeRequests: {
                    keyArgs: ['state', 'reviewState', 'reviewStates', 'mergedAfter'],
                  },
                  assignedMergeRequests: {
                    keyArgs: [
                      'state',
                      'reviewState',
                      'reviewStates',
                      'reviewerWildcardId',
                      'mergedAfter',
                    ],
                  },
                },
              },
              MergeRequestConnection: {
                fields: {
                  nodes: concatPagination(),
                },
              },
              UserMergeRequestInteraction: {
                merge(a) {
                  return a;
                },
              },
            },
          },
        },
      ),
    }),
    provide: { switchDashboardPath },
    render(createElement) {
      return createElement(App, {
        props: {
          lists,
        },
      });
    },
  });
}
