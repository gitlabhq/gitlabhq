import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import initReadMore from '~/read_more';
import Project from './project';

new Project(); // eslint-disable-line no-new
addShortcutsExtension(ShortcutsNavigation);

initReadMore();
