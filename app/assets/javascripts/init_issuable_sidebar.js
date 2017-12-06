/* eslint-disable no-new */
/* global MilestoneSelect */
import LabelsSelect from './labels_select';
import IssuableContext from './issuable_context';
/* global Sidebar */

import DueDateSelectors from './due_date_select';

export default () => {
  const sidebarOptions = JSON.parse(document.querySelector('.js-sidebar-options').innerHTML);

  new MilestoneSelect({
    full_path: sidebarOptions.fullPath,
  });
  new LabelsSelect();
  new IssuableContext(sidebarOptions.currentUser);
  new DueDateSelectors();
  window.sidebar = new Sidebar();
};
