import { RESOURCE_TYPE_MERGE_REQUEST } from '~/vue_shared/components/new_resource_dropdown/constants';
import searchUserProjectsWithMergeRequestsEnabled from '~/vue_shared/components/new_resource_dropdown/graphql/search_user_projects_with_merge_requests_enabled.query.graphql';
import { initMergeRequestDashboard } from '~/merge_request_dashboard';

initMergeRequestDashboard(document.getElementById('js-merge-request-dashboard'));

requestIdleCallback(async () => {
  const { initNewResourceDropdown } = await import(
    '~/vue_shared/components/new_resource_dropdown/init_new_resource_dropdown'
  );

  initNewResourceDropdown({
    resourceType: RESOURCE_TYPE_MERGE_REQUEST,
    query: searchUserProjectsWithMergeRequestsEnabled,
  });
});
