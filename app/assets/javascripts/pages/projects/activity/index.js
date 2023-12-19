import Activities from '~/activities';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';

new Activities(); // eslint-disable-line no-new
addShortcutsExtension(ShortcutsNavigation);
