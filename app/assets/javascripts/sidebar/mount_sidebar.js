import $ from 'jquery';
import Vue from 'vue';
import SidebarTimeTracking from './components/time_tracking/sidebar_time_tracking.vue';
import SidebarAssignees from './components/assignees/sidebar_assignees.vue';
import ConfidentialIssueSidebar from './components/confidential/confidential_issue_sidebar.vue';
import SidebarMoveIssue from './lib/sidebar_move_issue';
import LockIssueSidebar from './components/lock/lock_issue_sidebar.vue';
import sidebarParticipants from './components/participants/sidebar_participants.vue';
import sidebarSubscriptions from './components/subscriptions/sidebar_subscriptions.vue';
import Translate from '../vue_shared/translate';

Vue.use(Translate);

function mountAssigneesComponent(mediator) {
  const el = document.getElementById('js-vue-sidebar-assignees');

  if (!el) return;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      SidebarAssignees,
    },
    render: createElement => createElement('sidebar-assignees', {
      props: {
        mediator,
        field: el.dataset.field,
        signedIn: el.hasAttribute('data-signed-in'),
        issuableType: gl.utils.isInIssuePage() ? 'issue' : 'merge_request',
      },
    }),
  });
}

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

function mountParticipantsComponent(mediator) {
  const el = document.querySelector('.js-sidebar-participants-entry-point');

  // eslint-disable-next-line no-new
  if (!el) return;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      sidebarParticipants,
    },
    render: createElement => createElement('sidebar-participants', {
      props: {
        mediator,
      },
    }),
  });
}

function mountSubscriptionsComponent(mediator) {
  const el = document.querySelector('.js-sidebar-subscriptions-entry-point');

  if (!el) return;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      sidebarSubscriptions,
    },
    render: createElement => createElement('sidebar-subscriptions', {
      props: {
        mediator,
      },
    }),
  });
}

function mountTimeTrackingComponent() {
  const el = document.getElementById('issuable-time-tracker');

  if (!el) return;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      SidebarTimeTracking,
    },
    render: createElement => createElement('sidebar-time-tracking', {}),
  });
}

export function mountSidebar(mediator) {
  mountAssigneesComponent(mediator);
  mountConfidentialComponent(mediator);
  mountLockComponent(mediator);
  mountParticipantsComponent(mediator);
  mountSubscriptionsComponent(mediator);

  new SidebarMoveIssue(
    mediator,
    $('.js-move-issue'),
    $('.js-move-issue-confirmation-button'),
  ).init();

  mountTimeTrackingComponent();
}

export function getSidebarOptions() {
  return JSON.parse(document.querySelector('.js-sidebar-options').innerHTML);
}
