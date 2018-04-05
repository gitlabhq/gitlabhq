import projectSelect from '~/project_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import { FILTERED_SEARCH } from '~/pages/constants';
import FilteredSearchTokenKeysIssues from 'ee/filtered_search/filtered_search_token_keys_issues';

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: FILTERED_SEARCH.ISSUES,
    filteredSearchTokenKeys: FilteredSearchTokenKeysIssues,
    isGroupDecendent: true,
  });
  projectSelect();
});
