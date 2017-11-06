import Vue from 'vue';
import SidebarTimeTracking from './components/time_tracking/sidebar_time_tracking';
import SidebarAssignees from './components/assignees/sidebar_assignees';
import ConfidentialIssueSidebar from './components/confidential/confidential_issue_sidebar.vue';
import SidebarMoveIssue from './lib/sidebar_move_issue';
import LockIssueSidebar from './components/lock/lock_issue_sidebar.vue';
import sidebarParticipants from './components/participants/sidebar_participants.vue';
import sidebarSubscriptions from './components/subscriptions/sidebar_subscriptions.vue';
import Translate from '../vue_shared/translate';

import Mediator from './sidebar_mediator';

Vue.use(Translate);

function mountConfidentialComponent(mediator) {
  const el = document.getElementById('js-confidential-entry-point');

  if (!el) return;

  const dataNode = document.getElementById('js-confidential-issue-data');
  const initialData = JSON.parse(dataNode.innerHTML);

  const ConfidentialComp = Vue.extend(ConfidentialIssueSidebar);

  new ConfidentialComp({
    propsData: {
      isConfidential: initialData.is_confidential,
      isEditable: initialData.is_editable,
      service: mediator.service,
    },
  }).$mount(el);
}

function mountLockComponent(mediator) {
  const el = document.getElementById('js-lock-entry-point');

  if (!el) return;

  const dataNode = document.getElementById('js-lock-issue-data');
  const initialData = JSON.parse(dataNode.innerHTML);

  const LockComp = Vue.extend(LockIssueSidebar);

  new LockComp({
    propsData: {
      isLocked: initialData.is_locked,
      isEditable: initialData.is_editable,
      mediator,
      issuableType: gl.utils.isInIssuePage() ? 'issue' : 'merge_request',
    },
  }).$mount(el);
}

function mountParticipantsComponent() {
  const el = document.querySelector('.js-sidebar-participants-entry-point');

  if (!el) return;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      sidebarParticipants,
    },
    render: createElement => createElement('sidebar-participants', {}),
  });
}

function mountSubscriptionsComponent() {
  const el = document.querySelector('.js-sidebar-subscriptions-entry-point');

  if (!el) return;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      sidebarSubscriptions,
    },
    render: createElement => createElement('sidebar-subscriptions', {}),
  });
}

function domContentLoaded() {
  const sidebarOptions = JSON.parse(document.querySelector('.js-sidebar-options').innerHTML);
  const mediator = new Mediator(sidebarOptions);
  mediator.fetch();

  const sidebarAssigneesEl = document.getElementById('js-vue-sidebar-assignees');
  // Only create the sidebarAssignees vue app if it is found in the DOM
  // We currently do not use sidebarAssignees for the MR page
  if (sidebarAssigneesEl) {
    new Vue(SidebarAssignees).$mount(sidebarAssigneesEl);
  }

  mountConfidentialComponent(mediator);
  mountLockComponent(mediator);
  mountParticipantsComponent();
  mountSubscriptionsComponent();

  new SidebarMoveIssue(
    mediator,
    $('.js-move-issue'),
    $('.js-move-issue-confirmation-button'),
  ).init();

  new Vue(SidebarTimeTracking).$mount('#issuable-time-tracker');
}

document.addEventListener('DOMContentLoaded', domContentLoaded);

export default domContentLoaded;
