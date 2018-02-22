import Milestone from '~/milestone';
import Sidebar from '~/right_sidebar';
import MountMilestoneSidebar from '~/sidebar/mount_milestone_sidebar';

document.addEventListener('DOMContentLoaded', () => {
  new Milestone(); // eslint-disable-line no-new
  new Sidebar(); // eslint-disable-line no-new
  new MountMilestoneSidebar(); // eslint-disable-line no-new
});
