import IssuableIndex from '~/issuable_index';
import ShortcutsNavigation from '~/shortcuts_navigation';
import UsersSelect from '~/users_select';

export default () => {
  const filteredSearchEnabled = gl.FilteredSearchManager && document.querySelector('.filtered-search');

  if (filteredSearchEnabled) {
    const filteredSearchManager = new gl.FilteredSearchManager('merge_requests');
    filteredSearchManager.setup();
  }

  new IssuableIndex('merge_request_'); // eslint-disable-line no-new
  new ShortcutsNavigation(); // eslint-disable-line no-new
  new UsersSelect(); // eslint-disable-line no-new
};
