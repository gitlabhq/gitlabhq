import { parseBoolean } from '~/lib/utils/common_utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import TimeTracker from './components/time_tracking/time_tracker.vue';

export default class SidebarMilestone {
  constructor() {
    const el = document.querySelector('.js-sidebar-time-tracking-root');

    if (!el) return;

    const { timeEstimate, timeSpent, humanTimeEstimate, humanTimeSpent, limitToHours, iid } =
      el.dataset;

    initVueApp({
      el,
      name: 'SidebarMilestoneRoot',
      component: TimeTracker,
      props: {
        limitToHours: parseBoolean(limitToHours),
        issuableIid: iid.toString(),
        initialTimeTracking: {
          timeEstimate: parseInt(timeEstimate, 10),
          totalTimeSpent: parseInt(timeSpent, 10),
          humanTimeEstimate,
          humanTotalTimeSpent: humanTimeSpent,
        },
        canAddTimeEntries: false,
        canSetTimeEstimate: false,
      },
    });
  }
}
