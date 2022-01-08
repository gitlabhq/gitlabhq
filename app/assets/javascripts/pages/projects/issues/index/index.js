import IssuableFilteredSearchTokenKeys from 'ee_else_ce/filtered_search/issuable_filtered_search_token_keys';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { initCsvImportExportButtons, initIssuableByEmail } from '~/issuable';
import { initBulkUpdateSidebar, initIssueStatusSelect } from '~/issuable/bulk_update_sidebar';
import { mountIssuesListApp, mountJiraIssuesListApp } from '~/issues_list';
import initManualOrdering from '~/issues/manual_ordering';
import { FILTERED_SEARCH } from '~/filtered_search/constants';
import { ISSUABLE_INDEX } from '~/issuable/constants';
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

  initBulkUpdateSidebar(ISSUABLE_INDEX.ISSUE);
  initIssueStatusSelect();
  new UsersSelect(); // eslint-disable-line no-new

  initCsvImportExportButtons();
  initIssuableByEmail();
  initManualOrdering();
}

new ShortcutsNavigation(); // eslint-disable-line no-new

mountJiraIssuesListApp();
