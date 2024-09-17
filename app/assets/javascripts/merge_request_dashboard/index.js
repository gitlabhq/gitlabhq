import { concatPagination } from '@apollo/client/utilities';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import App from './components/app.vue';

export function initMergeRequestDashboard(el) {
  Vue.use(VueApollo);

  const { lists, switch_dashboard_path: switchDashboardPath } = JSON.parse(el.dataset.initialData);

  const keyArgs = [
    'state',
    'reviewState',
    'reviewStates',
    'reviewerWildcardId',
    'mergedAfter',
    'assignedReviewStates',
    'reviewerReviewStates',
  ];

  return new Vue({
    el,
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(
        {},
        {
          cacheConfig: {
            typePolicies: {
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
