import projectSelect from '~/project_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import { FILTERED_SEARCH } from '~/pages/constants';
import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';

document.addEventListener('DOMContentLoaded', () => {
  FilteredSearchTokenKeys.addExtraTokensForMergeRequests();

  initFilteredSearch({
    page: FILTERED_SEARCH.MERGE_REQUESTS,
    isGroupDecendent: true,
    filteredSearchTokenKeys: FilteredSearchTokenKeys,
  });
  projectSelect();
});
