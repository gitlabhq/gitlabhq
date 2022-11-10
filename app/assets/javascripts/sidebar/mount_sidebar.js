import $ from 'jquery';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import initInviteMembersModal from '~/invite_members/init_invite_members_modal';
import initInviteMembersTrigger from '~/invite_members/init_invite_members_trigger';
import { IssuableType } from '~/issues/constants';
import {
  isInIssuePage,
  isInDesignPage,
  isInIncidentPage,
  isInMRPage,
  parseBoolean,
} from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import CollapsedAssigneeList from '~/sidebar/components/assignees/collapsed_assignee_list.vue';
import SidebarAssigneesWidget from '~/sidebar/components/assignees/sidebar_assignees_widget.vue';
import SidebarConfidentialityWidget from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import SidebarDueDateWidget from '~/sidebar/components/date/sidebar_date_widget.vue';
import MilestoneDropdown from '~/sidebar/components/milestone/milestone_dropdown.vue';
import SidebarParticipantsWidget from '~/sidebar/components/participants/sidebar_participants_widget.vue';
import SidebarReferenceWidget from '~/sidebar/components/reference/sidebar_reference_widget.vue';
import SidebarDropdownWidget from '~/sidebar/components/sidebar_dropdown_widget.vue';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import trackShowInviteMemberLink from '~/sidebar/track_invite_members';
import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_vue/constants';
import LabelsSelectWidget from '~/vue_shared/components/sidebar/labels_select_widget/labels_select_root.vue';
import { LabelType } from '~/vue_shared/components/sidebar/labels_select_widget/constants';
import Translate from '../vue_shared/translate';
import SidebarAssignees from './components/assignees/sidebar_assignees.vue';
import CopyEmailToClipboard from './components/copy_email_to_clipboard.vue';
import SidebarEscalationStatus from './components/incidents/sidebar_escalation_status.vue';
import IssuableLockForm from './components/lock/issuable_lock_form.vue';
import SidebarReviewers from './components/reviewers/sidebar_reviewers.vue';
import SidebarReviewersInputs from './components/reviewers/sidebar_reviewers_inputs.vue';
import SidebarSeverity from './components/severity/sidebar_severity.vue';
import SidebarSubscriptionsWidget from './components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTimeTracking from './components/time_tracking/sidebar_time_tracking.vue';
import { IssuableAttributeType } from './constants';
import SidebarMoveIssue from './lib/sidebar_move_issue';
import CrmContacts from './components/crm_contacts/crm_contacts.vue';

Vue.use(Translate);
Vue.use(VueApollo);

function getSidebarOptions(sidebarOptEl = document.querySelector('.js-sidebar-options')) {
  return JSON.parse(sidebarOptEl.innerHTML);
}

function mountSidebarToDoWidget() {
  const el = document.querySelector('.js-issuable-todo');

  if (!el) {
    return false;
  }

  const { projectPath, iid, id } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarTodoRoot',
    apolloProvider,
    components: {
      SidebarTodoWidget,
    },
    provide: {
      isClassicSidebar: true,
    },
    render: (createElement) =>
      createElement('sidebar-todo-widget', {
        props: {
          fullPath: projectPath,
          issuableId:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? convertToGraphQLId(TYPE_ISSUE, id)
              : convertToGraphQLId(TYPE_MERGE_REQUEST, id),
          issuableIid: iid,
          issuableType:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? IssuableType.Issue
              : IssuableType.MergeRequest,
        },
      }),
  });
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
    name: 'SidebarAssigneesRoot',
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
          signedIn: Object.prototype.hasOwnProperty.call(el.dataset, 'signedIn'),
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
  const isIssuablePage = isInIssuePage() || isInIncidentPage() || isInDesignPage();
  const issuableType = isIssuablePage ? IssuableType.Issue : IssuableType.MergeRequest;
  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'SidebarAssigneesRoot',
    apolloProvider,
    components: {
      SidebarAssigneesWidget,
    },
    provide: {
      canUpdate: editable,
      directlyInviteMembers: Object.prototype.hasOwnProperty.call(
        el.dataset,
        'directlyInviteMembers',
      ),
    },
    render: (createElement) =>
      createElement('sidebar-assignees-widget', {
        props: {
          iid: String(iid),
          fullPath,
          issuableType,
          issuableId: id,
          allowMultipleAssignees: !el.dataset.maxAssignees || el.dataset.maxAssignees > 1,
          editable,
        },
        scopedSlots: {
          collapsed: ({ users }) =>
            createElement(CollapsedAssigneeList, {
              props: {
                users,
                issuableType,
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
    name: 'SidebarReviewersRoot',
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

  const reviewersInputEl = document.querySelector('.js-reviewers-inputs');

  if (reviewersInputEl) {
    // eslint-disable-next-line no-new
    new Vue({
      el: reviewersInputEl,
      render(createElement) {
        return createElement(SidebarReviewersInputs);
      },
    });
  }

  const reviewerDropdown = document.querySelector('.js-sidebar-reviewer-dropdown');

  if (reviewerDropdown) {
    trackShowInviteMemberLink(reviewerDropdown);
  }
}

function mountCrmContactsComponent() {
  const el = document.getElementById('js-issue-crm-contacts');

  if (!el) return;

  const { issueId, groupIssuesPath } = el.dataset;
  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'SidebarCrmContactsRoot',
    apolloProvider,
    components: {
      CrmContacts,
    },
    render: (createElement) =>
      createElement('crm-contacts', {
        props: {
          issueId,
          groupIssuesPath,
        },
      }),
  });
}

function mountMilestoneSelect() {
  const el = document.querySelector('.js-milestone-select');

  if (!el) {
    return false;
  }

  const { canEdit, projectPath, issueIid } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarMilestoneRoot',
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

export function mountMilestoneDropdown() {
  const el = document.querySelector('.js-milestone-dropdown');

  if (!el) {
    return null;
  }

  Vue.use(VueApollo);

  const {
    canAdminMilestone,
    fullPath,
    inputName,
    milestoneId,
    milestoneTitle,
    projectMilestonesPath,
    workspaceType,
  } = el.dataset;

  return new Vue({
    el,
    name: 'MilestoneDropdownRoot',
    apolloProvider,
    render(createElement) {
      return createElement(MilestoneDropdown, {
        props: {
          attrWorkspacePath: fullPath,
          canAdminMilestone,
          inputName,
          issuableType: isInIssuePage() ? IssuableType.Issue : IssuableType.MergeRequest,
          milestoneId,
          milestoneTitle,
          projectMilestonesPath,
          workspaceType,
        },
      });
    },
  });
}

export function mountSidebarLabels() {
  const el = document.querySelector('.js-sidebar-labels');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    name: 'SidebarLabelsRoot',
    apolloProvider,

    components: {
      LabelsSelectWidget,
    },
    provide: {
      ...el.dataset,
      canUpdate: parseBoolean(el.dataset.canEdit),
      allowLabelCreate: parseBoolean(el.dataset.allowLabelCreate),
      allowLabelEdit: parseBoolean(el.dataset.canEdit),
      allowScopedLabels: parseBoolean(el.dataset.allowScopedLabels),
      isClassicSidebar: true,
    },
    render: (createElement) =>
      createElement('labels-select-widget', {
        props: {
          iid: String(el.dataset.iid),
          fullPath: el.dataset.projectPath,
          allowLabelRemove: parseBoolean(el.dataset.canEdit),
          allowMultiselect: true,
          footerCreateLabelTitle: __('Create project label'),
          footerManageLabelTitle: __('Manage project labels'),
          labelsCreateTitle: __('Create project label'),
          labelsFilterBasePath: el.dataset.projectIssuesPath,
          variant: DropdownVariant.Sidebar,
          issuableType:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? IssuableType.Issue
              : IssuableType.MergeRequest,
          workspaceType: 'project',
          attrWorkspacePath: el.dataset.projectPath,
          labelCreateType: LabelType.project,
        },
        class: ['block labels js-labels-block'],
        scopedSlots: {
          default: () => __('None'),
        },
      }),
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
    name: 'SidebarConfidentialRoot',
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
    name: 'SidebarDueDateRoot',
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
    name: 'SidebarReferenceRoot',
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

function mountLockComponent(store) {
  const el = document.getElementById('js-lock-entry-point');

  if (!el || !store) {
    return;
  }

  const { fullPath, editable } = getSidebarOptions();

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'SidebarLockRoot',
    store,
    provide: {
      fullPath,
    },
    render: (createElement) =>
      createElement(IssuableLockForm, {
        props: {
          isEditable: editable,
        },
      }),
  });
}

function mountParticipantsComponent() {
  const el = document.querySelector('.js-sidebar-participants-entry-point');

  if (!el) return;

  const { fullPath, iid } = getSidebarOptions();

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'SidebarParticipantsRoot',
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
    name: 'SidebarSubscriptionsRoot',
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
    name: 'SidebarTimeTrackingRoot',
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

  const { fullPath, iid, severity, editable } = getSidebarOptions();

  return new Vue({
    el: severityContainerEl,
    name: 'SidebarSeverityRoot',
    apolloProvider,
    components: {
      SidebarSeverity,
    },
    provide: {
      canUpdate: editable,
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

function mountEscalationStatusComponent() {
  const statusContainerEl = document.querySelector('#js-escalation-status');

  if (!statusContainerEl) {
    return false;
  }

  const { issuableType } = getSidebarOptions();
  const { canUpdate, issueIid, projectPath } = statusContainerEl.dataset;

  return new Vue({
    el: statusContainerEl,
    apolloProvider,
    components: {
      SidebarEscalationStatus,
    },
    provide: {
      canUpdate: parseBoolean(canUpdate),
    },
    render: (createElement) =>
      createElement('sidebar-escalation-status', {
        props: {
          iid: issueIid,
          issuableType,
          projectPath,
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
    name: 'SidebarCopyEmailRoot',
    render: (createElement) =>
      createElement(CopyEmailToClipboard, { props: { issueEmailAddress: createNoteEmail } }),
  });
}

const isAssigneesWidgetShown =
  (isInIssuePage() || isInDesignPage() || isInMRPage()) && gon.features.issueAssigneesWidget;

export function mountSidebar(mediator, store) {
  initInviteMembersModal();
  initInviteMembersTrigger();

  mountSidebarToDoWidget();
  if (isAssigneesWidgetShown) {
    mountAssigneesComponent();
  } else {
    mountAssigneesComponentDeprecated(mediator);
  }
  mountReviewersComponent(mediator);
  mountCrmContactsComponent();
  mountSidebarLabels();
  mountMilestoneSelect();
  mountConfidentialComponent(mediator);
  mountDueDateComponent(mediator);
  mountReferenceComponent(mediator);
  mountLockComponent(store);
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

  mountEscalationStatusComponent();
}

export { getSidebarOptions };
