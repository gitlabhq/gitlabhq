import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { parseBoolean } from '~/lib/utils/common_utils';
import { defaultClient } from '~/graphql_shared/issuable_client';
import MergeRequestsListApp from './components/merge_requests_list_app.vue';

export async function mountMergeRequestListsApp() {
  const el = document.querySelector('.js-merge-request-list-root');

  if (!el) {
    return null;
  }

  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const {
    fullPath,
    hasAnyMergeRequests,
    initialSort,
    isPublicVisibilityRestricted,
    isSignedIn,
  } = el.dataset;

  return new Vue({
    el,
    name: 'MergeRequestsListRoot',
    apolloProvider: new VueApollo({
      defaultClient,
    }),
    router: new VueRouter({
      base: window.location.pathname,
      mode: 'history',
      routes: [{ path: '/' }],
    }),
    provide: {
      fullPath,
      hasAnyMergeRequests: parseBoolean(hasAnyMergeRequests),
      initialSort,
      isPublicVisibilityRestricted: parseBoolean(isPublicVisibilityRestricted),
      isSignedIn: parseBoolean(isSignedIn),
    },
    render: (createComponent) => createComponent(MergeRequestsListApp),
  });
}
