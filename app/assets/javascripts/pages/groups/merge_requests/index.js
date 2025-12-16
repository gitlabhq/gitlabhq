import getMergeRequestsQuery from 'ee_else_ce/merge_requests/list/queries/group/get_merge_requests.query.graphql';
import getMergeRequestsCountsQuery from 'ee_else_ce/merge_requests/list/queries/group/get_merge_requests_counts.query.graphql';
import getMergeRequestsApprovalsQuery from 'ee_else_ce/merge_requests/list/queries/group/get_merge_requests_approvals.query.graphql';
import { initBulkUpdateSidebar, mountMergeRequestListsApp } from '~/merge_requests/list';

const ISSUABLE_BULK_UPDATE_PREFIX = 'merge_request_';

initBulkUpdateSidebar(ISSUABLE_BULK_UPDATE_PREFIX);

mountMergeRequestListsApp({
  getMergeRequestsQuery,
  getMergeRequestsCountsQuery,
  getMergeRequestsApprovalsQuery,
  isProject: false,
});
