import { concatPagination } from '@apollo/client/utilities';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import createDefaultClient from '~/lib/graphql';
import App from './components/app.vue';

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

  return new Vue({
    el,
    router,
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
    provide: {
      mergeRequestsSearchDashboardPath: el.dataset.mergeRequestsSearchDashboardPath,
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
