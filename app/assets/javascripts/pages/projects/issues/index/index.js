import IssuableFilteredSearchTokenKeys from 'ee_else_ce/filtered_search/issuable_filtered_search_token_keys';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import initCsvImportExportButtons from '~/issuable/init_csv_import_export_buttons';
import initIssuableByEmail from '~/issuable/init_issuable_by_email';
import IssuableIndex from '~/issuable_index';
import { mountIssuablesListApp, mountIssuesListApp, mountJiraIssuesListApp } from '~/issues_list';
import initManualOrdering from '~/manual_ordering';
import { FILTERED_SEARCH } from '~/pages/constants';
import { ISSUABLE_INDEX } from '~/pages/projects/constants';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import UsersSelect from '~/users_select';

if (gon.features?.vueIssuesList) {
  mountIssuesListApp();
} else {
  IssuableFilteredSearchTokenKeys.addExtraTokensForIssues();

  initFilteredSearch({
    page: FILTERED_SEARCH.ISSUES,
    filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
    useDefaultState: true,
  });

  new IssuableIndex(ISSUABLE_INDEX.ISSUE); // eslint-disable-line no-new
  new UsersSelect(); // eslint-disable-line no-new

  initCsvImportExportButtons();
  initIssuableByEmail();
  initManualOrdering();

  if (gon.features?.vueIssuablesList) {
    mountIssuablesListApp();
  }
}

new ShortcutsNavigation(); // eslint-disable-line no-new

mountJiraIssuesListApp();
