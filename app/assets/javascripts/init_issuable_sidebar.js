/* eslint-disable no-new */

import MilestoneSelect from './milestone_select';
import LabelsSelect from './labels_select';
import IssuableContext from './issuable_context';
import Sidebar from './right_sidebar';

import DueDateSelectors from './due_date_select';

export default () => {
  const sidebarOptions = JSON.parse(document.querySelector('.js-sidebar-options').innerHTML);

  new MilestoneSelect({
    full_path: sidebarOptions.fullPath,
  });
  new LabelsSelect();
  new IssuableContext(sidebarOptions.currentUser);
  new DueDateSelectors();
  Sidebar.initialize();
};
