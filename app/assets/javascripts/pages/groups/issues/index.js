import projectSelect from '~/project_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import { FILTERED_SEARCH } from '~/pages/constants';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: FILTERED_SEARCH.ISSUES,
    isGroupDecendent: true,
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  });
  projectSelect();
});
