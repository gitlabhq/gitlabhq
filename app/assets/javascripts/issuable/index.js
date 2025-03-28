import Sidebar from '~/right_sidebar';
import { getSidebarOptions } from '~/sidebar/mount_sidebar';
import issuableBulkUpdateActions from './issuable_bulk_update_actions';
import IssuableBulkUpdateSidebar from './issuable_bulk_update_sidebar';
import IssuableContext from './issuable_context';

export function initBulkUpdateSidebar(prefixId) {
  const el = document.querySelector('.issues-bulk-update');

  if (!el) {
    return;
  }

  issuableBulkUpdateActions.init({ prefixId });
  new IssuableBulkUpdateSidebar(); // eslint-disable-line no-new
}

export function initIssuableSidebar() {
  const el = document.querySelector('.js-sidebar-options');

  if (!el) {
    return;
  }

  const sidebarOptions = getSidebarOptions(el);

  new IssuableContext(sidebarOptions.currentUser); // eslint-disable-line no-new
  Sidebar.initialize();
}
