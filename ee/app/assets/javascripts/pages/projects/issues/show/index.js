import initShow from '~/pages/projects/issues/show';
import initSidebarBundle from 'ee/sidebar/sidebar_bundle';

document.addEventListener('DOMContentLoaded', () => {
  initShow();
  initSidebarBundle();
});
