/* eslint-disable no-new */
/* global MilestoneSelect */
/* global LabelsSelect */
/* global IssuableContext */
/* global Sidebar */

export default () => {
  const sidebarOptions = JSON.parse(document.querySelector('.js-sidebar-options').innerHTML);

  new MilestoneSelect({
    full_path: sidebarOptions.fullPath,
  });
  new LabelsSelect();
  new IssuableContext(sidebarOptions.currentUser);
  gl.Subscription.bindAll('.subscription');
  new gl.DueDateSelectors();
  window.sidebar = new Sidebar();
};
