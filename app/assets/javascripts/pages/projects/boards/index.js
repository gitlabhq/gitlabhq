/* eslint-disable no-new */
import UsersSelect from '~/users_select';
import ShortcutsNavigation from '~/shortcuts_navigation';
import initBoards from '~/boards/boards_bundle';

export default () => {
  new UsersSelect();
  new ShortcutsNavigation();
  initBoards();
};
