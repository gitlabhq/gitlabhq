import projectSelect from '~/project_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import { FILTERED_SEARCH } from '~/pages/constants';
<<<<<<< HEAD
import IssuesFilteredSearchTokenKeysEE from 'ee/filtered_search/issues_filtered_search_token_keys';
=======
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
>>>>>>> upstream/master

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: FILTERED_SEARCH.ISSUES,
    isGroupDecendent: true,
<<<<<<< HEAD
    filteredSearchTokenKeys: IssuesFilteredSearchTokenKeysEE,
=======
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
>>>>>>> upstream/master
  });
  projectSelect();
});
