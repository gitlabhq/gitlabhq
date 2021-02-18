import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import initBoards from '~/boards';
import UsersSelect from '~/users_select';

document.addEventListener('DOMContentLoaded', () => {
  new UsersSelect(); // eslint-disable-line no-new
  new ShortcutsNavigation(); // eslint-disable-line no-new
  initBoards();
});
