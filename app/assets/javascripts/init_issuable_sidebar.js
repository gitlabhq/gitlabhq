/* eslint-disable no-new */
/* global MilestoneSelect */
/* global LabelsSelect */
/* global IssuableContext */
/* global Sidebar */

import DueDateSelectors from './due_date_select';

export default () => {
  const sidebarOptions = JSON.parse(document.querySelector('.js-sidebar-options').innerHTML);

  new MilestoneSelect({
    full_path: sidebarOptions.fullPath,
  });
  new LabelsSelect();
  new IssuableContext(sidebarOptions.currentUser);
  gl.Subscription.bindAll('.subscription');
  new DueDateSelectors();
  window.sidebar = new Sidebar();
};
