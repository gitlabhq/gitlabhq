import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { parseBoolean } from '@gitlab/frontend-utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import TimeTracker from './components/time_tracking/time_tracker.vue';

Vue.use(VueApollo);

export default class SidebarMilestone {
  constructor() {
    const el = document.querySelector('.js-sidebar-time-tracking-root');

    if (!el) return;

    const { timeEstimate, timeSpent, humanTimeEstimate, humanTimeSpent, limitToHours, iid } =
      el.dataset;

    initVueApp({
      el,
      name: 'SidebarMilestoneRoot',
      apolloProvider: new VueApollo({
        defaultClient: createDefaultClient(),
      }),
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
