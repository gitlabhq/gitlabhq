import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initShow from '../show';

document.addEventListener('DOMContentLoaded', () => {
  initShow();
  initSidebarBundle();
});
