import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import initManualOrdering from '~/manual_ordering';
import { FILTERED_SEARCH } from '~/pages/constants';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import projectSelect from '~/project_select';

initFilteredSearch({
  page: FILTERED_SEARCH.ISSUES,
  filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  useDefaultState: true,
});

projectSelect();
initManualOrdering();
