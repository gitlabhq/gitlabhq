import projectSelect from '~/project_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/pages/constants';
import initManualOrdering from '~/manual_ordering';

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: FILTERED_SEARCH.ISSUES,
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  });

  projectSelect();
  initManualOrdering();
});
