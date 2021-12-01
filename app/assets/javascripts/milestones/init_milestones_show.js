/* eslint-disable no-new */

import Milestone from '~/milestones/milestone';
import Sidebar from '~/right_sidebar';
import MountMilestoneSidebar from '~/sidebar/mount_milestone_sidebar';

export default () => {
  new Milestone();
  new Sidebar();
  new MountMilestoneSidebar();
};
