/* eslint-disable no-new */

import IssuableIndex from '~/issuable_index';
import ShortcutsNavigation from '~/shortcuts_navigation';
import UsersSelect from '~/users_select';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import { FILTERED_SEARCH } from '~/pages/constants';
import { ISSUABLE_INDEX } from '~/pages/projects/constants';

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: FILTERED_SEARCH.ISSUES,
  });
  new IssuableIndex(ISSUABLE_INDEX.ISSUE);

  new ShortcutsNavigation();
  new UsersSelect();
});
