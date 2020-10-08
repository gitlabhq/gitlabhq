/* eslint-disable no-new */

import IssuableFilteredSearchTokenKeys from 'ee_else_ce/filtered_search/issuable_filtered_search_token_keys';
import IssuableIndex from '~/issuable_index';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import UsersSelect from '~/users_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import { FILTERED_SEARCH } from '~/pages/constants';
import { ISSUABLE_INDEX } from '~/pages/projects/constants';
import initIssuablesList from '~/issues_list';
import initManualOrdering from '~/manual_ordering';
import { showLearnGitLabIssuesPopover } from '~/onboarding_issues';

IssuableFilteredSearchTokenKeys.addExtraTokensForIssues();

initFilteredSearch({
  page: FILTERED_SEARCH.ISSUES,
  filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
  useDefaultState: true,
});

new IssuableIndex(ISSUABLE_INDEX.ISSUE);
new ShortcutsNavigation();
new UsersSelect();

initManualOrdering();
initIssuablesList();
showLearnGitLabIssuesPopover();
