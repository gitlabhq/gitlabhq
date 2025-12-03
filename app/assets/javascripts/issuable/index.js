import Sidebar from '~/right_sidebar';
import { getSidebarOptions } from '~/sidebar/mount_sidebar';
import IssuableContext from './issuable_context';

export function initIssuableSidebar() {
  const el = document.querySelector('.js-sidebar-options');

  if (!el) {
    return;
  }

  const sidebarOptions = getSidebarOptions(el);

  new IssuableContext(sidebarOptions.currentUser); // eslint-disable-line no-new
  Sidebar.initialize();
}
