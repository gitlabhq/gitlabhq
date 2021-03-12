import addExtraTokensForMergeRequests from 'ee_else_ce/filtered_search/add_extra_tokens_for_merge_requests';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import initCsvImportExportButtons from '~/issuable/init_csv_import_export_buttons';
import initIssuableByEmail from '~/issuable/init_issuable_by_email';
import IssuableIndex from '~/issuable_index';
import { FILTERED_SEARCH } from '~/pages/constants';
import { ISSUABLE_INDEX } from '~/pages/projects/constants';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import UsersSelect from '~/users_select';

new IssuableIndex(ISSUABLE_INDEX.MERGE_REQUEST); // eslint-disable-line no-new

addExtraTokensForMergeRequests(IssuableFilteredSearchTokenKeys);

initFilteredSearch({
  page: FILTERED_SEARCH.MERGE_REQUESTS,
  filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  useDefaultState: true,
});

new UsersSelect(); // eslint-disable-line no-new
new ShortcutsNavigation(); // eslint-disable-line no-new

initIssuableByEmail();
initCsvImportExportButtons();
