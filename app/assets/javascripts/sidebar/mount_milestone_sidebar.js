import Vue from 'vue';
import timeTracker from './components/time_tracking/time_tracker.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default class SidebarMilestone {
  constructor() {
    const el = document.getElementById('issuable-time-tracker');

    if (!el) return;

    const { timeEstimate, timeSpent, humanTimeEstimate, humanTimeSpent, limitToHours } = el.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el,
      components: {
        timeTracker,
      },
      render: createElement =>
        createElement('timeTracker', {
          props: {
            timeEstimate: parseInt(timeEstimate, 10),
            timeSpent: parseInt(timeSpent, 10),
            humanTimeEstimate,
            humanTimeSpent,
            limitToHours: parseBoolean(limitToHours),
          },
        }),
    });
  }
}
