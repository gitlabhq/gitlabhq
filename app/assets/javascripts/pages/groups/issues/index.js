import projectSelect from '~/project_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import { FILTERED_SEARCH } from '~/pages/constants';
import IssuableFilteredSearchTokenKeys from 'ee_else_ce/filtered_search/issuable_filtered_search_token_keys';
import initManualOrdering from '~/manual_ordering';

document.addEventListener('DOMContentLoaded', () => {
  IssuableFilteredSearchTokenKeys.addExtraTokensForIssues();

  initFilteredSearch({
    page: FILTERED_SEARCH.ISSUES,
    isGroupDecendent: true,
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  });
  projectSelect();
  initManualOrdering();
});
