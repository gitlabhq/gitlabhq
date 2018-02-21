import Milestone from '~/milestone';
import Sidebar from '~/right_sidebar';

document.addEventListener('DOMContentLoaded', () => {
  new Milestone(); // eslint-disable-line no-new
  new Sidebar(); // eslint-disable-line no-new
});
