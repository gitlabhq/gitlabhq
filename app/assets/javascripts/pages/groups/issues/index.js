import projectSelect from '~/project_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import { FILTERED_SEARCH } from '~/pages/constants';
<<<<<<< HEAD
import FilteredSearchTokenKeysIssues from 'ee/filtered_search/filtered_search_token_keys_issues';
=======
import IssuesFilteredSearchTokenKeys from '~/filtered_search/issues_filtered_search_token_keys';
>>>>>>> d4387d88767... make FilteredSearchTokenKeys generic

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: FILTERED_SEARCH.ISSUES,
    filteredSearchTokenKeys: FilteredSearchTokenKeysIssues,
    isGroupDecendent: true,
    filteredSearchTokenKeys: IssuesFilteredSearchTokenKeys,
  });
  projectSelect();
});
