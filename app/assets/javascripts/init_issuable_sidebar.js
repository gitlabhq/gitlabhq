/* eslint-disable no-new */

import { mountSidebarLabels, getSidebarOptions } from '~/sidebar/mount_sidebar';
import IssuableContext from './issuable_context';
import LabelsSelect from './labels_select';
import MilestoneSelect from './milestone_select';
import Sidebar from './right_sidebar';

export default () => {
  const sidebarOptEl = document.querySelector('.js-sidebar-options');

  if (!sidebarOptEl) return;

  const sidebarOptions = getSidebarOptions(sidebarOptEl);

  new MilestoneSelect({
    full_path: sidebarOptions.fullPath,
  });
  new LabelsSelect();
  new IssuableContext(sidebarOptions.currentUser);
  Sidebar.initialize();

  mountSidebarLabels();
};
