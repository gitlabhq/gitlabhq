import { concatPagination } from '@apollo/client/utilities';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';
import App from './components/app.vue';

export function initMergeRequestDashboard(el) {
  Vue.use(VueApollo);

  const { lists } = JSON.parse(el.dataset.initialData);

  return new Vue({
    el,
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(
        {
          Mutation: {
            setIsShowingLabels(_, { isShowingLabels }, { cache }) {
              cache.writeQuery({
                query: isShowingLabelsQuery,
                data: { isShowingLabels },
              });
              return isShowingLabels;
            },
          },
        },
        {
          cacheConfig: {
            typePolicies: {
              Query: {
                fields: {
                  isShowingLabels: {
                    read(currentState) {
                      return currentState ?? true;
                    },
                  },
                },
              },
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
            },
          },
        },
      ),
    }),
    render(createElement) {
      return createElement(App, {
        props: {
          lists,
        },
      });
    },
  });
}
