import IssuableFilteredSearchTokenKeys from 'ee_else_ce/filtered_search/issuable_filtered_search_token_keys';
import { initBulkUpdateSidebar } from '~/issuable/bulk_update_sidebar';
import { mountIssuesListApp } from '~/issues/list';
import initManualOrdering from '~/issues/manual_ordering';
import { FILTERED_SEARCH } from '~/filtered_search/constants';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import projectSelect from '~/project_select';

if (gon.features?.vueIssuesList) {
  mountIssuesListApp();
} else {
  const ISSUE_BULK_UPDATE_PREFIX = 'issue_';

  IssuableFilteredSearchTokenKeys.addExtraTokensForIssues();
  IssuableFilteredSearchTokenKeys.removeTokensForKeys('release');
  initBulkUpdateSidebar(ISSUE_BULK_UPDATE_PREFIX);

  initFilteredSearch({
    page: FILTERED_SEARCH.ISSUES,
    isGroupDecendent: true,
    useDefaultState: true,
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  });
  projectSelect();
  initManualOrdering();
}
