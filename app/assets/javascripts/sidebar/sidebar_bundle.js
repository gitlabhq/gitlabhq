import Vue from 'vue';
import sidebarTimeTracking from './components/time_tracking/sidebar_time_tracking';
import sidebarAssignees from './components/assignees/sidebar_assignees';

import Mediator from './sidebar_mediator';

document.addEventListener('DOMContentLoaded', () => {
  const mediator = new Mediator(gl.sidebarOptions);
  mediator.fetch();

  new Vue(sidebarAssignees).$mount('#js-vue-sidebar-assignees');
  new Vue(sidebarTimeTracking).$mount('#issuable-time-tracker');
});

