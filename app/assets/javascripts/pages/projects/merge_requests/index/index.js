import addExtraTokensForMergeRequests from 'ee_else_ce/filtered_search/add_extra_tokens_for_merge_requests';
import getMergeRequestsQuery from 'ee_else_ce/merge_requests/list/queries/project/get_merge_requests.query.graphql';
import getMergeRequestsCountsQuery from 'ee_else_ce/merge_requests/list/queries/project/get_merge_requests_counts.query.graphql';
import getMergeRequestsApprovalsQuery from 'ee_else_ce/merge_requests/list/queries/project/get_merge_requests_approvals.query.graphql';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/filtered_search/constants';
import { initBulkUpdateSidebar, initCsvImportExportButtons, initIssuableByEmail } from '~/issuable';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import { mountMoreActionsDropdown, mountMergeRequestListsApp } from '~/merge_requests/list';

initBulkUpdateSidebar('merge_request_');

addExtraTokensForMergeRequests(IssuableFilteredSearchTokenKeys);
IssuableFilteredSearchTokenKeys.removeTokensForKeys('iteration');

initFilteredSearch({
  page: FILTERED_SEARCH.MERGE_REQUESTS,
  filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  useDefaultState: true,
});

addShortcutsExtension(ShortcutsNavigation);

initIssuableByEmail();
initCsvImportExportButtons();
mountMoreActionsDropdown();
mountMergeRequestListsApp({
  getMergeRequestsQuery,
  getMergeRequestsApprovalsQuery,
  getMergeRequestsCountsQuery,
});
