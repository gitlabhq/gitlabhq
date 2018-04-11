import '~/pages/groups/milestones/show/index';
import UserCallout from '~/user_callout';
import initBurndownChart from 'ee/burndown_chart';

document.addEventListener('DOMContentLoaded', () => {
  new UserCallout(); // eslint-disable-line no-new
  initBurndownChart();
});
