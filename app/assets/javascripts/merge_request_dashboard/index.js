import { concatPagination } from '@apollo/client/utilities';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { parseBoolean } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';
import App from './components/app.vue';
import ConfigDropdown from './components/config_dropdown.vue';

export function initMergeRequestDashboard(el) {
  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const { tabs } = JSON.parse(el.dataset.initialData);
  const router = new VueRouter({
    mode: 'history',
    base: el.dataset.basePath,
    routes: [{ path: '/:filter' }],
  });

  const keyArgs = [
    'state',
    'reviewState',
    'reviewStates',
    'reviewerWildcardId',
    'mergedAfter',
    'assignedReviewStates',
    'reviewerReviewStates',
  ];
  const apolloProvider = new VueApollo({
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
                    return currentState ?? false;
                  },
                },
              },
            },
            CurrentUser: {
              fields: {
                assignedMergeRequests: {
                  keyArgs,
                  merge: true,
                },
                reviewRequestedMergeRequests: {
                  keyArgs,
                  merge: true,
                },
                assigneeOrReviewerMergeRequests: {
                  keyArgs,
                  merge: true,
                },
              },
            },
            MergeRequestConnection: {
              fields: {
                nodes: concatPagination(),
              },
            },
            MergeRequestReviewer: {
              keyFields: false,
            },
          },
        },
      },
    ),
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: document.getElementById('js-merge-request-dashboard-config'),
    apolloProvider,
    render(h) {
      return h(ConfigDropdown);
    },
  });

  return new Vue({
    el,
    router,
    apolloProvider,
    provide: {
      mergeRequestsSearchDashboardPath: el.dataset.mergeRequestsSearchDashboardPath,
      showMergeChecksSuccess: parseBoolean(el.dataset.showMergeChecksSuccess),
      realtimeEnabled: parseBoolean(el.dataset.realtimeEnabled),
    },
    render(createElement) {
      return createElement(App, {
        props: {
          tabs,
        },
      });
    },
  });
}
