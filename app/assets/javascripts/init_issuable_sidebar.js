/* eslint-disable no-new */
/* global MilestoneSelect */
/* global LabelsSelect */
/* global IssuableContext */
/* global Sidebar */

export default () => {
  new MilestoneSelect({
    full_path: gl.sidebarOptions.fullPath,
  });
  new LabelsSelect();
  new IssuableContext(gl.sidebarOptions.currentUser);
  gl.Subscription.bindAll('.subscription');
  new gl.DueDateSelectors();
  window.sidebar = new Sidebar();
};
