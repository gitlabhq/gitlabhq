import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initMergeConflicts from '~/merge_conflicts/merge_conflicts_bundle';

document.addEventListener('DOMContentLoaded', () => {
  initSidebarBundle();
  initMergeConflicts();
});
