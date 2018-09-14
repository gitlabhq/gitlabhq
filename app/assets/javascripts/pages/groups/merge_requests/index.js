import projectSelect from '~/project_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
<<<<<<< HEAD
import IssuesFilteredSearchTokenKeys from '~/filtered_search/issues_filtered_search_token_keys';
=======
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
>>>>>>> upstream/master
import { FILTERED_SEARCH } from '~/pages/constants';

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: FILTERED_SEARCH.MERGE_REQUESTS,
    isGroupDecendent: true,
<<<<<<< HEAD
    filteredSearchTokenKeys: IssuesFilteredSearchTokenKeys,
=======
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
>>>>>>> upstream/master
  });
  projectSelect();
});
