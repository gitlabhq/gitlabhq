import Project from './project';
import ShortcutsNavigation from '../../shortcuts_navigation';

document.addEventListener('DOMContentLoaded', () => {
  new Project(); // eslint-disable-line no-new
  new ShortcutsNavigation(); // eslint-disable-line no-new
});
