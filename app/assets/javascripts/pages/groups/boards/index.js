import UsersSelect from '~/users_select';
import ShortcutsNavigation from '~/shortcuts_navigation';
import initBoards from '~/boards';

document.addEventListener('DOMContentLoaded', () => {
  new UsersSelect(); // eslint-disable-line no-new
  new ShortcutsNavigation(); // eslint-disable-line no-new
  initBoards();
});
