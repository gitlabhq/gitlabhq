import addExtraTokensForMergeRequests from 'ee_else_ce/filtered_search/add_extra_tokens_for_merge_requests';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import {
  initBulkUpdateSidebar,
  initStatusDropdown,
  initSubscriptionsDropdown,
} from '~/issuable/bulk_update_sidebar';
import { FILTERED_SEARCH } from '~/filtered_search/constants';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import projectSelect from '~/project_select';

const ISSUABLE_BULK_UPDATE_PREFIX = 'merge_request_';

addExtraTokensForMergeRequests(IssuableFilteredSearchTokenKeys);
initBulkUpdateSidebar(ISSUABLE_BULK_UPDATE_PREFIX);
initStatusDropdown();
initSubscriptionsDropdown();

initFilteredSearch({
  page: FILTERED_SEARCH.MERGE_REQUESTS,
  isGroupDecendent: true,
  useDefaultState: true,
  filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
});
projectSelect();
