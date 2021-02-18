import initMergeConflicts from '~/merge_conflicts/merge_conflicts_bundle';
import initSidebarBundle from '~/sidebar/sidebar_bundle';

document.addEventListener('DOMContentLoaded', () => {
  initSidebarBundle();
  initMergeConflicts();
});
