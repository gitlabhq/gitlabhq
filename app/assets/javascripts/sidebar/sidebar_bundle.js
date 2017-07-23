import Vue from 'vue';
import sidebarTimeTracking from './components/time_tracking/sidebar_time_tracking';
import sidebarAssignees from './components/assignees/sidebar_assignees';

import Mediator from './sidebar_mediator';

function domContentLoaded() {
  const mediator = new Mediator(gl.sidebarOptions);
  mediator.fetch();

  const sidebarAssigneesEl = document.querySelector('#js-vue-sidebar-assignees');

  // Only create the sidebarAssignees vue app if it is found in the DOM
  // We currently do not use sidebarAssignees for the MR page
  if (sidebarAssigneesEl) {
    new Vue(sidebarAssignees).$mount(sidebarAssigneesEl);
  }

  new Vue(sidebarTimeTracking).$mount('#issuable-time-tracker');
}

document.addEventListener('DOMContentLoaded', domContentLoaded);

export default domContentLoaded;
