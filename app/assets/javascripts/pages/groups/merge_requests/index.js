import addExtraTokensForMergeRequests from 'ee_else_ce/filtered_search/add_extra_tokens_for_merge_requests';
import projectSelect from '~/project_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import issuableInitBulkUpdateSidebar from '~/issuable_init_bulk_update_sidebar';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/pages/constants';

const ISSUABLE_BULK_UPDATE_PREFIX = 'merge_request_';

document.addEventListener('DOMContentLoaded', () => {
  addExtraTokensForMergeRequests(IssuableFilteredSearchTokenKeys);
  issuableInitBulkUpdateSidebar.init(ISSUABLE_BULK_UPDATE_PREFIX);

  initFilteredSearch({
    page: FILTERED_SEARCH.MERGE_REQUESTS,
    isGroupDecendent: true,
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  });
  projectSelect();
});
