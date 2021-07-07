import $ from 'jquery';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createFlash from '~/flash';
import initInviteMembersModal from '~/invite_members/init_invite_members_modal';
import initInviteMembersTrigger from '~/invite_members/init_invite_members_trigger';
import { IssuableType } from '~/issue_show/constants';
import {
  isInIssuePage,
  isInDesignPage,
  isInIncidentPage,
  parseBoolean,
} from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import CollapsedAssigneeList from '~/sidebar/components/assignees/collapsed_assignee_list.vue';
import SidebarAssigneesWidget from '~/sidebar/components/assignees/sidebar_assignees_widget.vue';
import SidebarConfidentialityWidget from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import SidebarDueDateWidget from '~/sidebar/components/date/sidebar_date_widget.vue';
import SidebarParticipantsWidget from '~/sidebar/components/participants/sidebar_participants_widget.vue';
import SidebarReferenceWidget from '~/sidebar/components/reference/sidebar_reference_widget.vue';
import SidebarDropdownWidget from '~/sidebar/components/sidebar_dropdown_widget.vue';
import { apolloProvider } from '~/sidebar/graphql';
import trackShowInviteMemberLink from '~/sidebar/track_invite_members';
import Translate from '../vue_shared/translate';
import SidebarAssignees from './components/assignees/sidebar_assignees.vue';
import CopyEmailToClipboard from './components/copy_email_to_clipboard.vue';
import SidebarLabels from './components/labels/sidebar_labels.vue';
import IssuableLockForm from './components/lock/issuable_lock_form.vue';
import SidebarReviewers from './components/reviewers/sidebar_reviewers.vue';
import SidebarSeverity from './components/severity/sidebar_severity.vue';
import SidebarSubscriptionsWidget from './components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTimeTracking from './components/time_tracking/sidebar_time_tracking.vue';
import { IssuableAttributeType } from './constants';
import SidebarMoveIssue from './lib/sidebar_move_issue';

Vue.use(Translate);
Vue.use(VueApollo);

function getSidebarOptions(sidebarOptEl = document.querySelector('.js-sidebar-options')) {
  return JSON.parse(sidebarOptEl.innerHTML);
}

function getSidebarAssigneeAvailabilityData() {
  const sidebarAssigneeEl = document.querySelectorAll('.js-sidebar-assignee-data input');
  return Array.from(sidebarAssigneeEl)
    .map((el) => el.dataset)
    .reduce(
      (acc, { username, availability = '' }) => ({
        ...acc,
        [username]: availability,
      }),
      {},
    );
}

function mountAssigneesComponentDeprecated(mediator) {
  const el = document.getElementById('js-vue-sidebar-assignees');

  if (!el) return;

  const { id, iid, fullPath } = getSidebarOptions();
  const assigneeAvailabilityStatus = getSidebarAssigneeAvailabilityData();
  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    components: {
      SidebarAssignees,
    },
    render: (createElement) =>
      createElement('sidebar-assignees', {
        props: {
          mediator,
          issuableIid: String(iid),
          projectPath: fullPath,
          field: el.dataset.field,
          signedIn: el.hasAttribute('data-signed-in'),
          issuableType:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? IssuableType.Issue
              : IssuableType.MergeRequest,
          issuableId: id,
          assigneeAvailabilityStatus,
        },
      }),
  });
}

function mountAssigneesComponent() {
  const el = document.getElementById('js-vue-sidebar-assignees');

  if (!el) return;

  const { id, iid, fullPath, editable } = getSidebarOptions();
  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    components: {
      SidebarAssigneesWidget,
    },
    provide: {
      canUpdate: editable,
      directlyInviteMembers: el.hasAttribute('data-directly-invite-members'),
    },
    render: (createElement) =>
      createElement('sidebar-assignees-widget', {
        props: {
          iid: String(iid),
          fullPath,
          issuableType:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? IssuableType.Issue
              : IssuableType.MergeRequest,
          issuableId: id,
          allowMultipleAssignees: !el.dataset.maxAssignees,
        },
        scopedSlots: {
          collapsed: ({ users, onClick }) =>
            createElement(CollapsedAssigneeList, {
              props: {
                users,
              },
              nativeOn: {
                click: onClick,
              },
            }),
        },
      }),
  });

  const assigneeDropdown = document.querySelector('.js-sidebar-assignee-dropdown');

  if (assigneeDropdown) {
    trackShowInviteMemberLink(assigneeDropdown);
  }
}

function mountReviewersComponent(mediator) {
  const el = document.getElementById('js-vue-sidebar-reviewers');

  if (!el) return;

  const { iid, fullPath } = getSidebarOptions();
  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    components: {
      SidebarReviewers,
    },
    render: (createElement) =>
      createElement('sidebar-reviewers', {
        props: {
          mediator,
          issuableIid: String(iid),
          projectPath: fullPath,
          field: el.dataset.field,
          issuableType:
            isInIssuePage() || isInDesignPage() ? IssuableType.Issue : IssuableType.MergeRequest,
        },
      }),
  });

  const reviewerDropdown = document.querySelector('.js-sidebar-reviewer-dropdown');

  if (reviewerDropdown) {
    trackShowInviteMemberLink(reviewerDropdown);
  }
}

function mountMilestoneSelect() {
  const el = document.querySelector('.js-milestone-select');

  if (!el) {
    return false;
  }

  const { canEdit, projectPath, issueIid } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    components: {
      SidebarDropdownWidget,
    },
    provide: {
      canUpdate: parseBoolean(canEdit),
      isClassicSidebar: true,
    },
    render: (createElement) =>
      createElement('sidebar-dropdown-widget', {
        props: {
          attrWorkspacePath: projectPath,
          workspacePath: projectPath,
          iid: issueIid,
          issuableType:
            isInIssuePage() || isInDesignPage() ? IssuableType.Issue : IssuableType.MergeRequest,
          issuableAttribute: IssuableAttributeType.Milestone,
          icon: 'clock',
        },
      }),
  });
}

export function mountSidebarLabels() {
  const el = document.querySelector('.js-sidebar-labels');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    apolloProvider,
    provide: {
      ...el.dataset,
      allowLabelCreate: parseBoolean(el.dataset.allowLabelCreate),
      allowLabelEdit: parseBoolean(el.dataset.canEdit),
      allowScopedLabels: parseBoolean(el.dataset.allowScopedLabels),
      initiallySelectedLabels: JSON.parse(el.dataset.selectedLabels),
    },
    render: (createElement) => createElement(SidebarLabels),
  });
}

function mountConfidentialComponent() {
  const el = document.getElementById('js-confidential-entry-point');
  if (!el) {
    return;
  }

  const { fullPath, iid } = getSidebarOptions();
  const dataNode = document.getElementById('js-confidential-issue-data');
  const initialData = JSON.parse(dataNode.innerHTML);

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    components: {
      SidebarConfidentialityWidget,
    },
    provide: {
      canUpdate: initialData.is_editable,
      isClassicSidebar: true,
    },

    render: (createElement) =>
      createElement('sidebar-confidentiality-widget', {
        props: {
          iid: String(iid),
          fullPath,
          issuableType:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? IssuableType.Issue
              : IssuableType.MergeRequest,
        },
      }),
  });
}

function mountDueDateComponent() {
  const el = document.getElementById('js-due-date-entry-point');
  if (!el) {
    return;
  }

  const { fullPath, iid, editable } = getSidebarOptions();

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    components: {
      SidebarDueDateWidget,
    },
    provide: {
      canUpdate: editable,
    },

    render: (createElement) =>
      createElement('sidebar-due-date-widget', {
        props: {
          iid: String(iid),
          fullPath,
          issuableType: IssuableType.Issue,
        },
      }),
  });
}

function mountReferenceComponent() {
  const el = document.getElementById('js-reference-entry-point');
  if (!el) {
    return;
  }

  const { fullPath, iid } = getSidebarOptions();

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    components: {
      SidebarReferenceWidget,
    },
    provide: {
      iid: String(iid),
      fullPath,
    },

    render: (createElement) =>
      createElement('sidebar-reference-widget', {
        props: {
          issuableType:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? IssuableType.Issue
              : IssuableType.MergeRequest,
        },
      }),
  });
}

function mountLockComponent() {
  const el = document.getElementById('js-lock-entry-point');

  if (!el) {
    return;
  }

  const { fullPath } = getSidebarOptions();

  const dataNode = document.getElementById('js-lock-issue-data');
  const initialData = JSON.parse(dataNode.innerHTML);

  let importStore;
  if (isInIssuePage() || isInIncidentPage()) {
    importStore = import(/* webpackChunkName: 'notesStore' */ '~/notes/stores').then(
      ({ store }) => store,
    );
  } else {
    importStore = import(/* webpackChunkName: 'mrNotesStore' */ '~/mr_notes/stores').then(
      (store) => store.default,
    );
  }

  importStore
    .then(
      (store) =>
        new Vue({
          el,
          store,
          provide: {
            fullPath,
          },
          render: (createElement) =>
            createElement(IssuableLockForm, {
              props: {
                isEditable: initialData.is_editable,
              },
            }),
        }),
    )
    .catch(() => {
      createFlash({ message: __('Failed to load sidebar lock status') });
    });
}

function mountParticipantsComponent() {
  const el = document.querySelector('.js-sidebar-participants-entry-point');

  if (!el) return;

  const { fullPath, iid } = getSidebarOptions();

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    components: {
      SidebarParticipantsWidget,
    },
    render: (createElement) =>
      createElement('sidebar-participants-widget', {
        props: {
          iid: String(iid),
          fullPath,
          issuableType:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? IssuableType.Issue
              : IssuableType.MergeRequest,
        },
      }),
  });
}

function mountSubscriptionsComponent() {
  const el = document.querySelector('.js-sidebar-subscriptions-entry-point');

  if (!el) return;

  const { fullPath, iid, editable } = getSidebarOptions();

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    components: {
      SidebarSubscriptionsWidget,
    },
    provide: {
      canUpdate: editable,
    },
    render: (createElement) =>
      createElement('sidebar-subscriptions-widget', {
        props: {
          iid: String(iid),
          fullPath,
          issuableType:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? IssuableType.Issue
              : IssuableType.MergeRequest,
        },
      }),
  });
}

function mountTimeTrackingComponent() {
  const el = document.getElementById('issuable-time-tracker');
  const { id, iid, fullPath, issuableType, timeTrackingLimitToHours } = getSidebarOptions();

  if (!el) return;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    provide: { issuableType },
    render: (createElement) =>
      createElement(SidebarTimeTracking, {
        props: {
          fullPath,
          issuableId: id.toString(),
          issuableIid: iid.toString(),
          limitToHours: timeTrackingLimitToHours,
        },
      }),
  });
}

function mountSeverityComponent() {
  const severityContainerEl = document.querySelector('#js-severity');

  if (!severityContainerEl) {
    return false;
  }

  const { fullPath, iid, severity } = getSidebarOptions();

  return new Vue({
    el: severityContainerEl,
    apolloProvider,
    components: {
      SidebarSeverity,
    },
    render: (createElement) =>
      createElement('sidebar-severity', {
        props: {
          projectPath: fullPath,
          iid: String(iid),
          initialSeverity: severity.toUpperCase(),
        },
      }),
  });
}

function mountCopyEmailComponent() {
  const el = document.getElementById('issuable-copy-email');

  if (!el) return;

  const { createNoteEmail } = getSidebarOptions();

  // eslint-disable-next-line no-new
  new Vue({
    el,
    render: (createElement) =>
      createElement(CopyEmailToClipboard, { props: { issueEmailAddress: createNoteEmail } }),
  });
}

const isAssigneesWidgetShown =
  (isInIssuePage() || isInDesignPage()) && gon.features.issueAssigneesWidget;

export function mountSidebar(mediator) {
  initInviteMembersModal();
  initInviteMembersTrigger();

  if (isAssigneesWidgetShown) {
    mountAssigneesComponent();
  } else {
    mountAssigneesComponentDeprecated(mediator);
  }
  mountReviewersComponent(mediator);
  mountMilestoneSelect();
  mountConfidentialComponent(mediator);
  mountDueDateComponent(mediator);
  mountReferenceComponent(mediator);
  mountLockComponent();
  mountParticipantsComponent();
  mountSubscriptionsComponent();
  mountCopyEmailComponent();

  new SidebarMoveIssue(
    mediator,
    $('.js-move-issue'),
    $('.js-move-issue-confirmation-button'),
  ).init();

  mountTimeTrackingComponent();

  mountSeverityComponent();
}

export { getSidebarOptions };
