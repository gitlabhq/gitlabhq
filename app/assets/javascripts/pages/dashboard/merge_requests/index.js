import { initNewResourceDropdown } from '~/vue_shared/components/new_resource_dropdown/init_new_resource_dropdown';
import { RESOURCE_TYPE_MERGE_REQUEST } from '~/vue_shared/components/new_resource_dropdown/constants';
import searchUserProjectsWithMergeRequestsEnabled from '~/vue_shared/components/new_resource_dropdown/graphql/search_user_projects_with_merge_requests_enabled.query.graphql';
import { initMergeRequestsDashboard } from './page';

initNewResourceDropdown({
  resourceType: RESOURCE_TYPE_MERGE_REQUEST,
  query: searchUserProjectsWithMergeRequestsEnabled,
});

const el = document.getElementById('js-merge-request-dashboard');

if (el) {
  requestIdleCallback(async () => {
    const { initMergeRequestDashboard } = await import('~/merge_request_dashboard');

    initMergeRequestDashboard(el);
  });
} else {
  initMergeRequestsDashboard();
}
