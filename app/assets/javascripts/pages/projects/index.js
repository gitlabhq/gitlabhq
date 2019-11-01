import Project from './project';
import ShortcutsNavigation from '../../behaviors/shortcuts/shortcuts_navigation';
import initCreateCluster from '~/create_cluster/init_create_cluster';

document.addEventListener('DOMContentLoaded', () => {
  initCreateCluster(document, gon);

  new Project(); // eslint-disable-line no-new
  new ShortcutsNavigation(); // eslint-disable-line no-new
});
