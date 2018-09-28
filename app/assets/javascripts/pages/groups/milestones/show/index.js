import initMilestonesShow from '~/pages/milestones/shared/init_milestones_show';
import initDeleteMilestoneModal from '~/pages/milestones/shared/delete_milestone_modal_init';

import Milestone from '~/milestone';

document.addEventListener('DOMContentLoaded', () => {
  initMilestonesShow();
  initDeleteMilestoneModal();
  Milestone.initDeprecationMessage();
});
