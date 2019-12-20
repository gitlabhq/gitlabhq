import IssuableFilteredSearchTokenKeys from 'ee_else_ce/filtered_search/issuable_filtered_search_token_keys';
import initIssuablesList from '~/issuables_list';
import projectSelect from '~/project_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import issuableInitBulkUpdateSidebar from '~/issuable_init_bulk_update_sidebar';
import { FILTERED_SEARCH } from '~/pages/constants';
import initManualOrdering from '~/manual_ordering';

const ISSUE_BULK_UPDATE_PREFIX = 'issue_';

document.addEventListener('DOMContentLoaded', () => {
  IssuableFilteredSearchTokenKeys.addExtraTokensForIssues();
  issuableInitBulkUpdateSidebar.init(ISSUE_BULK_UPDATE_PREFIX);

  initIssuablesList();

  initFilteredSearch({
    page: FILTERED_SEARCH.ISSUES,
    isGroupDecendent: true,
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  });
  projectSelect();
  initManualOrdering();
});
