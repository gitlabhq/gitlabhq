import addExtraTokensForMergeRequests from 'ee_else_ce/filtered_search/add_extra_tokens_for_merge_requests';
import { createFilteredSearchTokenKeys } from '~/filtered_search/issuable_filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/filtered_search/constants';
import initFilteredSearch from '~/pages/search/init_filtered_search';

export const initMergeRequestsDashboard = () => {
  const IssuableFilteredSearchTokenKeys = createFilteredSearchTokenKeys({
    disableReleaseFilter: true,
  });

  addExtraTokensForMergeRequests(IssuableFilteredSearchTokenKeys, {
    disableBranchFilter: true,
    disableReleaseFilter: true,
    disableEnvironmentFilter: true,
  });

  initFilteredSearch({
    page: FILTERED_SEARCH.MERGE_REQUESTS,
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
    useDefaultState: true,
  });
};
