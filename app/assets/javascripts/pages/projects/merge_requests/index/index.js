import getMergeRequestsQuery from 'ee_else_ce/merge_requests/list/queries/project/get_merge_requests.query.graphql';
import getMergeRequestsCountsQuery from 'ee_else_ce/merge_requests/list/queries/project/get_merge_requests_counts.query.graphql';
import getMergeRequestsApprovalsQuery from 'ee_else_ce/merge_requests/list/queries/project/get_merge_requests_approvals.query.graphql';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { initBulkUpdateSidebar } from '~/issuable';
import { mountMergeRequestListsApp } from '~/merge_requests/list';

initBulkUpdateSidebar('merge_request_');

addShortcutsExtension(ShortcutsNavigation);

mountMergeRequestListsApp({
  getMergeRequestsQuery,
  getMergeRequestsApprovalsQuery,
  getMergeRequestsCountsQuery,
});
