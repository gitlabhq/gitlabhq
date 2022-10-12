import addExtraTokensForMergeRequests from 'ee_else_ce/filtered_search/add_extra_tokens_for_merge_requests';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import { initCsvImportExportButtons, initIssuableByEmail } from '~/issuable';
import {
  initBulkUpdateSidebar,
  initStatusDropdown,
  initSubscriptionsDropdown,
} from '~/issuable/bulk_update_sidebar';
import { FILTERED_SEARCH } from '~/filtered_search/constants';
import { ISSUABLE_INDEX } from '~/issuable/constants';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import UsersSelect from '~/users_select';

initBulkUpdateSidebar(ISSUABLE_INDEX.MERGE_REQUEST);
initStatusDropdown();
initSubscriptionsDropdown();

addExtraTokensForMergeRequests(IssuableFilteredSearchTokenKeys);
IssuableFilteredSearchTokenKeys.removeTokensForKeys('iteration');

initFilteredSearch({
  page: FILTERED_SEARCH.MERGE_REQUESTS,
  filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  useDefaultState: true,
});

new UsersSelect(); // eslint-disable-line no-new
new ShortcutsNavigation(); // eslint-disable-line no-new

initIssuableByEmail();
initCsvImportExportButtons();
