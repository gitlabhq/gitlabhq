import addExtraTokensForMergeRequests from 'ee_else_ce/filtered_search/add_extra_tokens_for_merge_requests';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import issuableInitBulkUpdateSidebar from '~/issuable_bulk_update_sidebar/issuable_init_bulk_update_sidebar';
import { FILTERED_SEARCH } from '~/pages/constants';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import projectSelect from '~/project_select';

const ISSUABLE_BULK_UPDATE_PREFIX = 'merge_request_';

addExtraTokensForMergeRequests(IssuableFilteredSearchTokenKeys);
issuableInitBulkUpdateSidebar.init(ISSUABLE_BULK_UPDATE_PREFIX);

initFilteredSearch({
  page: FILTERED_SEARCH.MERGE_REQUESTS,
  isGroupDecendent: true,
  useDefaultState: true,
  filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
});
projectSelect();
