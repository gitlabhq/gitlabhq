/* eslint-disable no-new */

import IssuableIndex from '~/issuable_index';
import ShortcutsNavigation from '~/shortcuts_navigation';
import UsersSelect from '~/users_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import IssuesFilteredSearchTokenKeys from '~/filtered_search/issues_filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/pages/constants';
import { ISSUABLE_INDEX } from '~/pages/projects/constants';
import FilteredSearchTokenKeysIssues from 'ee/filtered_search/filtered_search_token_keys_issues';

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: FILTERED_SEARCH.ISSUES,
<<<<<<< HEAD
    filteredSearchTokenKeys: FilteredSearchTokenKeysIssues,
=======
    filteredSearchTokenKeys: IssuesFilteredSearchTokenKeys,
>>>>>>> d4387d88767... make FilteredSearchTokenKeys generic
  });
  new IssuableIndex(ISSUABLE_INDEX.ISSUE);

  new ShortcutsNavigation();
  new UsersSelect();
});
