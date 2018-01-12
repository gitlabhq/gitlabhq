
/* eslint-disable no-new */

import IssuableIndex from '~/issuable_index';
import ShortcutsNavigation from '~/shortcuts_navigation';
import UsersSelect from '~/users_select';

export default () => {
  const filteredSearchEnabled = gl.FilteredSearchManager && document.querySelector('.filtered-search');
  if (filteredSearchEnabled) {
    const filteredSearchManager = new gl.FilteredSearchManager('issues');
    filteredSearchManager.setup();
  }
  new IssuableIndex('issue_'); // eslint-disable no-new

  new ShortcutsNavigation();
  new UsersSelect(); // eslint-disable no-new
};
