/* eslint-disable no-new */
import UsersSelect from '~/users_select';
import ShortcutsNavigation from '~/shortcuts_navigation';
import '~/filtered_search/filtered_search_bundle';
import '~/boards/boards_bundle';

export default () => {
  new UsersSelect();
  new ShortcutsNavigation();
};
