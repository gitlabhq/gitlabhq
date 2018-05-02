import initMilestonesShow from '~/pages/milestones/shared/init_milestones_show';
import Milestone from '~/milestone';

document.addEventListener('DOMContentLoaded', () => {
  initMilestonesShow();

  Milestone.initDeprecationMessage();
});
