import Vue from 'vue';
import timeTracker from './components/time_tracking/time_tracker.vue';

export default class SidebarMilestone {
  constructor() {
    const el = document.getElementById('issuable-time-tracker');

    if (!el) return;

    // eslint-disable-next-line no-new
    new Vue({
      el,
      components: {
        timeTracker,
      },
      render: createElement => createElement('timeTracker', {
        props: {
          time_estimate: parseInt(el.dataset.timeEstimate, 10),
          time_spent: parseInt(el.dataset.timeSpent, 10),
          human_time_estimate: el.dataset.humanTimeEstimate,
          human_time_spent: el.dataset.humanTimeSpent,
          rootPath: '/',
        },
      }),
    });
  }
}
