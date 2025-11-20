import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { parseBoolean } from '~/lib/utils/common_utils';
import { defaultClient } from '~/graphql_shared/issuable_client';
import MergeRequestsListApp from './components/merge_requests_list_app.vue';

export async function mountMergeRequestListsApp({
  getMergeRequestsQuery,
  getMergeRequestsCountsQuery,
  getMergeRequestsApprovalsQuery,
  isProject = true,
} = {}) {
  const el = document.querySelector('.js-merge-request-list-root');

  if (!el) {
    return null;
  }

  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const {
    autocompleteAwardEmojisPath,
    mergeRequestSourceBranchesPath,
    mergeRequestTargetBranchesPath,
    fullPath,
    namespaceId,
    hasAnyMergeRequests,
    hasScopedLabelsFeature,
    initialSort,
    isPublicVisibilityRestricted,
    isSignedIn,
    newMergeRequestPath,
    showExportButton,
    issuableType,
    email,
    exportCsvPath,
    rssUrl,
    releasesEndpoint,
    canBulkUpdate,
    environmentNamesPath,
    mergeTrainsPath,
    initialEmail,
    emailsHelpPagePath,
    quickActionsHelpPath,
    markdownHelpPath,
    resetPath,
    showNewResourceDropdown,
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
      autocompleteAwardEmojisPath,
      mergeRequestSourceBranchesPath,
      mergeRequestTargetBranchesPath,
      hasAnyMergeRequests: parseBoolean(hasAnyMergeRequests),
      hasScopedLabelsFeature: parseBoolean(hasScopedLabelsFeature),
      initialSort,
      isPublicVisibilityRestricted: parseBoolean(isPublicVisibilityRestricted),
      isSignedIn: parseBoolean(isSignedIn),
      newMergeRequestPath,
      showExportButton: parseBoolean(showExportButton),
      issuableType,
      email,
      exportCsvPath,
      rssUrl,
      releasesEndpoint,
      canBulkUpdate: parseBoolean(canBulkUpdate),
      environmentNamesPath,
      mergeTrainsPath,
      initialEmail,
      emailsHelpPagePath,
      quickActionsHelpPath,
      markdownHelpPath,
      resetPath,
      getMergeRequestsQuery,
      getMergeRequestsCountsQuery,
      getMergeRequestsApprovalsQuery,
      isProject,
      namespaceId: namespaceId ? `${namespaceId}` : null,
      showNewResourceDropdown: parseBoolean(showNewResourceDropdown),
    },
    render: (createComponent) => createComponent(MergeRequestsListApp),
  });
}
