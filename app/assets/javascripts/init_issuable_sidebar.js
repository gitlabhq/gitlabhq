/* eslint-disable no-new */

import { getSidebarOptions } from '~/sidebar/mount_sidebar';
import IssuableContext from './issuable_context';
import Sidebar from './right_sidebar';

export default () => {
  const sidebarOptEl = document.querySelector('.js-sidebar-options');

  if (!sidebarOptEl) return;

  const sidebarOptions = getSidebarOptions(sidebarOptEl);

  new IssuableContext(sidebarOptions.currentUser);
  Sidebar.initialize();
};
