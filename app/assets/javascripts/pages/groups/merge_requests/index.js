import addExtraTokensForMergeRequests from 'ee_else_ce/filtered_search/add_extra_tokens_for_merge_requests';
import getMergeRequestsQuery from 'ee_else_ce/merge_requests/list/queries/group/get_merge_requests.query.graphql';
import getMergeRequestsCountsQuery from 'ee_else_ce/merge_requests/list/queries/group/get_merge_requests_counts.query.graphql';
import getMergeRequestsApprovalsQuery from 'ee_else_ce/merge_requests/list/queries/group/get_merge_requests_approvals.query.graphql';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/filtered_search/constants';
import { initBulkUpdateSidebar } from '~/issuable';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import { initNewResourceDropdown } from '~/vue_shared/components/new_resource_dropdown/init_new_resource_dropdown';
import { RESOURCE_TYPE_MERGE_REQUEST } from '~/vue_shared/components/new_resource_dropdown/constants';
import searchUserGroupProjectsWithMergeRequestsEnabled from '~/vue_shared/components/new_resource_dropdown/graphql/search_user_group_projects_with_merge_requests_enabled.query.graphql';
import { mountMergeRequestListsApp } from '~/merge_requests/list';

const ISSUABLE_BULK_UPDATE_PREFIX = 'merge_request_';

addExtraTokensForMergeRequests(IssuableFilteredSearchTokenKeys);
initBulkUpdateSidebar(ISSUABLE_BULK_UPDATE_PREFIX);

initFilteredSearch({
  page: FILTERED_SEARCH.MERGE_REQUESTS,
  isGroupDecendent: true,
  useDefaultState: true,
  filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
});
initNewResourceDropdown({
  resourceType: RESOURCE_TYPE_MERGE_REQUEST,
  query: searchUserGroupProjectsWithMergeRequestsEnabled,
  extractProjects: (data) => data?.group?.projects?.nodes,
});
mountMergeRequestListsApp({
  getMergeRequestsQuery,
  getMergeRequestsCountsQuery,
  getMergeRequestsApprovalsQuery,
  isProject: false,
});
