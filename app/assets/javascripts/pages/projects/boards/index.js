import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import initBoards from '~/boards';

addShortcutsExtension(ShortcutsNavigation);
initBoards();
