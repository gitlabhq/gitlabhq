/* eslint-disable no-new */

import IssuableFilteredSearchTokenKeys from 'ee_else_ce/filtered_search/issuable_filtered_search_token_keys';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import initCsvImportExportButtons from '~/issuable/init_csv_import_export_buttons';
import initIssuableByEmail from '~/issuable/init_issuable_by_email';
import IssuableIndex from '~/issuable_index';
import initIssuablesList, { initIssuesListApp } from '~/issues_list';
import initManualOrdering from '~/manual_ordering';
import { FILTERED_SEARCH } from '~/pages/constants';
import { ISSUABLE_INDEX } from '~/pages/projects/constants';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import UsersSelect from '~/users_select';

IssuableFilteredSearchTokenKeys.addExtraTokensForIssues();

initFilteredSearch({
  page: FILTERED_SEARCH.ISSUES,
  filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  useDefaultState: true,
});

if (gon.features?.vueIssuesList) {
  new IssuableIndex();
} else {
  new IssuableIndex(ISSUABLE_INDEX.ISSUE);
}

new ShortcutsNavigation();
new UsersSelect();

initManualOrdering();
initIssuablesList();
initIssuableByEmail();
initCsvImportExportButtons();
initIssuesListApp();
