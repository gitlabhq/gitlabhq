import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initShow from '../init_merge_request_show';

document.addEventListener('DOMContentLoaded', () => {
  initShow();
  initSidebarBundle();
});
