import Vue from 'vue';
import { IssuableType } from '~/issue_show/constants';
import { parseBoolean } from '~/lib/utils/common_utils';
import timeTracker from './components/time_tracking/time_tracker.vue';

export default class SidebarMilestone {
  constructor() {
    const el = document.getElementById('issuable-time-tracker');

    if (!el) return;

    const {
      timeEstimate,
      timeSpent,
      humanTimeEstimate,
      humanTimeSpent,
      limitToHours,
      iid,
    } = el.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el,
      components: {
        timeTracker,
      },
      provide: {
        issuableType: IssuableType.Milestone,
      },
      render: (createElement) =>
        createElement('timeTracker', {
          props: {
            limitToHours: parseBoolean(limitToHours),
            issuableIid: iid.toString(),
            initialTimeTracking: {
              timeEstimate: parseInt(timeEstimate, 10),
              totalTimeSpent: parseInt(timeSpent, 10),
              humanTimeEstimate,
              humanTotalTimeSpent: humanTimeSpent,
            },
          },
        }),
    });
  }
}
