import addExtraTokensForMergeRequests from 'ee_else_ce/filtered_search/add_extra_tokens_for_merge_requests';
import projectSelect from '~/project_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/pages/constants';

document.addEventListener('DOMContentLoaded', () => {
  addExtraTokensForMergeRequests(IssuableFilteredSearchTokenKeys);

  initFilteredSearch({
    page: FILTERED_SEARCH.MERGE_REQUESTS,
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  });

  projectSelect();
});
