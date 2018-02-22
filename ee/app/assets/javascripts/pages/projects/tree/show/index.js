import '~/pages/projects/tree/show/index';
import initPathLocks from 'ee/path_locks';

document.addEventListener('DOMContentLoaded', () => {
  if (document.querySelector('.js-tree-content').dataset.pathLocksAvailable === 'true') {
    initPathLocks(
      document.querySelector('.js-tree-content').dataset.pathLocksToggle,
      document.querySelector('.js-tree-content').dataset.pathLocksPath,
    );
  }
});
