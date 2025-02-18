import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { TYPENAME_ISSUE, TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST, WORKSPACE_PROJECT } from '~/issues/constants';
import { gqlClient } from '~/issues/list/graphql';
import {
  isInDesignPage,
  isInIncidentPage,
  isInIssuePage,
  parseBoolean,
} from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import Translate from '~/vue_shared/translate';
import UserSelect from '~/vue_shared/components/user_select/user_select.vue';
import CollapsedAssigneeList from './components/assignees/collapsed_assignee_list.vue';
import SidebarAssigneesWidget from './components/assignees/sidebar_assignees_widget.vue';
import CopyEmailToClipboard from './components/copy/copy_email_to_clipboard.vue';
import SidebarDueDateWidget from './components/date/sidebar_date_widget.vue';
import SidebarEscalationStatus from './components/incidents/sidebar_escalation_status.vue';
import LabelsSelectWidget from './components/labels/labels_select_widget/labels_select_root.vue';
import IssuableLockForm from './components/lock/issuable_lock_form.vue';
import MilestoneDropdown from './components/milestone/milestone_dropdown.vue';
import MoveIssuesButton from './components/move/move_issues_button.vue';
import SidebarParticipantsWidget from './components/participants/sidebar_participants_widget.vue';
import SidebarReferenceWidget from './components/copy/sidebar_reference_widget.vue';
import SidebarReviewers from './components/reviewers/sidebar_reviewers.vue';
import SidebarReviewersInputs from './components/reviewers/sidebar_reviewers_inputs.vue';
import SidebarSeverityWidget from './components/severity/sidebar_severity_widget.vue';
import SidebarDropdownWidget from './components/sidebar_dropdown_widget.vue';
import StatusDropdown from './components/status/status_dropdown.vue';
import SidebarSubscriptionsWidget from './components/subscriptions/sidebar_subscriptions_widget.vue';
import SubscriptionsDropdown from './components/subscriptions/subscriptions_dropdown.vue';
import SidebarTimeTracking from './components/time_tracking/sidebar_time_tracking.vue';
import SidebarTodoWidget from './components/todo_toggle/sidebar_todo_widget.vue';
import { IssuableAttributeType } from './constants';
import CrmContacts from './components/crm_contacts/crm_contacts.vue';
import trackShowInviteMemberLink from './track_invite_members';
import MoveIssueButton from './components/move/move_issue_button.vue';
import ConfidentialityDropdown from './components/confidential/confidentiality_dropdown.vue';

Vue.use(Translate);
Vue.use(VueApollo);

function getSidebarOptions(sidebarOptEl = document.querySelector('.js-sidebar-options')) {
  return JSON.parse(sidebarOptEl.innerHTML);
}

function mountSidebarTodoWidget() {
  const el = document.querySelector('.js-sidebar-todo-widget-root');

  if (!el) {
    return null;
  }

  const { projectPath, iid, id } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarTodoWidgetRoot',
    apolloProvider,
    provide: {
      isClassicSidebar: true,
    },
    render: (createElement) =>
      createElement(SidebarTodoWidget, {
        props: {
          fullPath: projectPath,
          issuableId:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? convertToGraphQLId(TYPENAME_ISSUE, id)
              : convertToGraphQLId(TYPENAME_MERGE_REQUEST, id),
          issuableIid: iid,
          issuableType:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? TYPE_ISSUE
              : TYPE_MERGE_REQUEST,
        },
      }),
  });
}

function mountSidebarAssigneesWidget() {
  const el = document.querySelector('.js-sidebar-assignees-root');

  if (!el) {
    return;
  }

  const { id, iid, fullPath, editable } = getSidebarOptions();
  const isIssuablePage = isInIssuePage() || isInIncidentPage() || isInDesignPage();
  const issuableType = isIssuablePage ? TYPE_ISSUE : TYPE_MERGE_REQUEST;
  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'SidebarAssigneesRoot',
    apolloProvider,
    provide: {
      canUpdate: parseBoolean(editable),
      directlyInviteMembers: Object.prototype.hasOwnProperty.call(
        el.dataset,
        'directlyInviteMembers',
      ),
    },
    render: (createElement) =>
      createElement(SidebarAssigneesWidget, {
        props: {
          iid: String(iid),
          fullPath,
          issuableType,
          issuableId: id,
          allowMultipleAssignees: !el.dataset.maxAssignees || el.dataset.maxAssignees > 1,
          editable: parseBoolean(editable),
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
}

function mountSidebarReviewers(mediator) {
  const el = document.querySelector('.js-sidebar-reviewers-root');

  if (!el) {
    return;
  }

  const {
    id,
    iid,
    fullPath,
    multipleApprovalRulesAvailable = false,
    directlyInviteMembers = false,
  } = getSidebarOptions();
  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'SidebarReviewersRoot',
    apolloProvider,
    provide: {
      issuableIid: String(iid),
      issuableId: String(id),
      projectPath: fullPath,
      multipleApprovalRulesAvailable: parseBoolean(multipleApprovalRulesAvailable),
      directlyInviteMembers: parseBoolean(directlyInviteMembers),
    },
    render: (createElement) =>
      createElement(SidebarReviewers, {
        props: {
          mediator,
          issuableIid: String(iid),
          projectPath: fullPath,
          field: el.dataset.field,
          issuableType: isInIssuePage() || isInDesignPage() ? TYPE_ISSUE : TYPE_MERGE_REQUEST,
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

function mountSidebarCrmContacts() {
  const el = document.querySelector('.js-sidebar-crm-contacts-root');

  if (!el) {
    return null;
  }

  const { issueId, groupIssuesPath } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarCrmContactsRoot',
    apolloProvider,
    render: (createElement) =>
      createElement(CrmContacts, {
        props: {
          issueId,
          groupIssuesPath,
        },
      }),
  });
}

function mountSidebarMilestoneWidget() {
  const el = document.querySelector('.js-sidebar-milestone-widget-root');

  if (!el) {
    return null;
  }

  const { canEdit, projectPath, issueIid } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarMilestoneWidgetRoot',
    apolloProvider,
    provide: {
      canUpdate: parseBoolean(canEdit),
      isClassicSidebar: true,
    },
    render: (createElement) =>
      createElement(SidebarDropdownWidget, {
        props: {
          attrWorkspacePath: projectPath,
          workspacePath: projectPath,
          iid: issueIid,
          issuableType:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? TYPE_ISSUE
              : TYPE_MERGE_REQUEST,
          issuableAttribute: IssuableAttributeType.Milestone,
          icon: 'milestone',
        },
      }),
  });
}

export function mountMilestoneDropdown() {
  const el = document.querySelector('.js-milestone-dropdown-root');

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
          issuableType: isInIssuePage() ? TYPE_ISSUE : TYPE_MERGE_REQUEST,
          milestoneId,
          milestoneTitle,
          projectMilestonesPath,
          workspaceType,
        },
      });
    },
  });
}

export function mountSidebarLabelsWidget() {
  const el = document.querySelector('.js-sidebar-labels-widget-root');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'SidebarLabelsWidgetRoot',
    apolloProvider,
    provide: {
      ...el.dataset,
      canUpdate: parseBoolean(el.dataset.canEdit),
      allowLabelCreate: parseBoolean(el.dataset.allowLabelCreate),
      allowLabelEdit: parseBoolean(el.dataset.canEdit),
      allowScopedLabels: parseBoolean(el.dataset.allowScopedLabels),
      isClassicSidebar: true,
    },
    render: (createElement) =>
      createElement(LabelsSelectWidget, {
        props: {
          iid: String(el.dataset.iid),
          fullPath: el.dataset.projectPath,
          allowLabelRemove: parseBoolean(el.dataset.canEdit),
          allowMultiselect: true,
          footerCreateLabelTitle: __('Create project label'),
          footerManageLabelTitle: __('Manage project labels'),
          labelsCreateTitle: __('Create project label'),
          labelsFilterBasePath: el.dataset.projectIssuesPath,
          issuableType:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? TYPE_ISSUE
              : TYPE_MERGE_REQUEST,
          workspaceType: WORKSPACE_PROJECT,
          attrWorkspacePath: el.dataset.projectPath,
          labelCreateType: WORKSPACE_PROJECT,
        },
        class: ['block labels js-labels-block'],
        scopedSlots: {
          default: () => __('None'),
        },
      }),
  });
}

function mountSidebarDueDateWidget() {
  const el = document.querySelector('.js-sidebar-due-date-widget-root');

  if (!el) {
    return null;
  }

  const { fullPath, iid, editable } = getSidebarOptions();

  return new Vue({
    el,
    name: 'SidebarDueDateWidgetRoot',
    apolloProvider,
    provide: {
      canUpdate: parseBoolean(editable),
    },
    render: (createElement) =>
      createElement(SidebarDueDateWidget, {
        props: {
          iid: String(iid),
          fullPath,
          issuableType: TYPE_ISSUE,
        },
      }),
  });
}

function mountSidebarReferenceWidget() {
  const el = document.querySelector('.js-sidebar-reference-widget-root');

  if (!el) {
    return null;
  }

  const { fullPath, iid } = getSidebarOptions();

  return new Vue({
    el,
    name: 'SidebarReferenceWidgetRoot',
    apolloProvider,
    provide: {
      iid: String(iid),
      fullPath,
    },
    render: (createElement) =>
      createElement(SidebarReferenceWidget, {
        props: {
          issuableType:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? TYPE_ISSUE
              : TYPE_MERGE_REQUEST,
        },
      }),
  });
}

function mountIssuableLockForm(store, pinia) {
  const el = document.querySelector('.js-sidebar-lock-root');

  if (!el || !store) {
    return null;
  }

  const { fullPath, editable } = getSidebarOptions();

  return new Vue({
    el,
    name: 'SidebarLockRoot',
    pinia,
    store,
    provide: {
      fullPath,
    },
    render: (createElement) =>
      createElement(IssuableLockForm, {
        props: {
          isEditable: parseBoolean(editable),
        },
      }),
  });
}

function mountSidebarParticipantsWidget() {
  const el = document.querySelector('.js-sidebar-participants-widget-root');

  if (!el) {
    return null;
  }

  const { fullPath, iid } = getSidebarOptions();

  return new Vue({
    el,
    name: 'SidebarParticipantsWidgetRoot',
    apolloProvider,
    render: (createElement) =>
      createElement(SidebarParticipantsWidget, {
        props: {
          iid: String(iid),
          fullPath,
          issuableType:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? TYPE_ISSUE
              : TYPE_MERGE_REQUEST,
        },
      }),
  });
}

function mountSidebarSubscriptionsWidget() {
  const el = document.querySelector('.js-sidebar-subscriptions-widget-root');

  if (!el) {
    return null;
  }

  const { fullPath, iid, editable } = getSidebarOptions();

  return new Vue({
    el,
    name: 'SidebarSubscriptionsWidgetRoot',
    apolloProvider,
    provide: {
      canUpdate: parseBoolean(editable),
    },
    render: (createElement) =>
      createElement(SidebarSubscriptionsWidget, {
        props: {
          iid: String(iid),
          fullPath,
          issuableType:
            isInIssuePage() || isInIncidentPage() || isInDesignPage()
              ? TYPE_ISSUE
              : TYPE_MERGE_REQUEST,
        },
      }),
  });
}

function mountSidebarTimeTracking() {
  const el = document.querySelector('.js-sidebar-time-tracking-root');

  const { id, iid, fullPath, issuableType, timeTrackingLimitToHours, canCreateTimelogs, editable } =
    getSidebarOptions();

  if (!el) {
    return null;
  }

  return new Vue({
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
          canAddTimeEntries: canCreateTimelogs,
          canSetTimeEstimate: parseBoolean(editable),
        },
      }),
  });
}

function mountSidebarSeverityWidget() {
  const el = document.querySelector('.js-sidebar-severity-widget-root');

  if (!el) {
    return null;
  }

  const { fullPath, iid, severity, editable } = getSidebarOptions();

  return new Vue({
    el,
    name: 'SidebarSeverityWidgetRoot',
    apolloProvider,
    provide: {
      canUpdate: parseBoolean(editable),
    },
    render: (createElement) =>
      createElement(SidebarSeverityWidget, {
        props: {
          projectPath: fullPath,
          iid: String(iid),
          initialSeverity: severity.toUpperCase(),
        },
      }),
  });
}

function mountSidebarEscalationStatus() {
  const el = document.querySelector('.js-sidebar-escalation-status-root');

  if (!el) {
    return null;
  }

  const { issuableType } = getSidebarOptions();
  const { canUpdate, issueIid, projectPath } = el.dataset;

  return new Vue({
    el,
    name: 'SidebarEscalationStatusRoot',
    apolloProvider,
    provide: {
      canUpdate: parseBoolean(canUpdate),
    },
    render: (createElement) =>
      createElement(SidebarEscalationStatus, {
        props: {
          iid: issueIid,
          issuableType,
          projectPath,
        },
      }),
  });
}

function mountCopyEmailToClipboard() {
  const el = document.querySelector('.js-sidebar-copy-email-root');

  if (!el) {
    return null;
  }

  const { createNoteEmail } = getSidebarOptions();

  return new Vue({
    el,
    name: 'SidebarCopyEmailRoot',
    render: (createElement) =>
      createElement(CopyEmailToClipboard, { props: { issueEmailAddress: createNoteEmail } }),
  });
}

export async function mountMoveIssuesButton() {
  const el = document.querySelector('.js-move-issues');

  if (!el) {
    return null;
  }

  Vue.use(VueApollo);

  return new Vue({
    el,
    name: 'MoveIssuesRoot',
    apolloProvider: new VueApollo({
      defaultClient: await gqlClient(),
    }),
    render: (createElement) =>
      createElement(MoveIssuesButton, {
        props: {
          projectFullPath: el.dataset.projectFullPath,
          projectsFetchPath: el.dataset.projectsFetchPath,
        },
      }),
  });
}

export function mountStatusDropdown() {
  const el = document.querySelector('.js-status-dropdown');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'StatusDropdownRoot',
    render: (createElement) => createElement(StatusDropdown),
  });
}

export function mountSubscriptionsDropdown() {
  const el = document.querySelector('.js-subscriptions-dropdown');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'SubscriptionsDropdownRoot',
    render: (createElement) => createElement(SubscriptionsDropdown),
  });
}

export function mountConfidentialityDropdown() {
  const el = document.querySelector('.js-confidentiality-dropdown');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'ConfidentialityDropdownRoot',
    render: (createElement) => createElement(ConfidentialityDropdown),
  });
}

export function mountMoveIssueButton() {
  const el = document.querySelector('.js-sidebar-move-issue-block');

  if (!el) {
    return null;
  }

  const { projectsAutocompleteEndpoint } = getSidebarOptions();
  const { projectFullPath, issueIid } = el.dataset;

  Vue.use(VueApollo);

  return new Vue({
    el,
    name: 'MoveIssueDropdownRoot',
    apolloProvider,
    provide: {
      projectsAutocompleteEndpoint,
      projectFullPath,
      issueIid,
    },
    render: (createElement) => createElement(MoveIssueButton),
  });
}

export function mountAssigneesDropdown() {
  const el = document.querySelector('.js-assignee-dropdown');
  const assigneeIdsInput = document.querySelector('.js-assignee-ids-input');

  if (!el || !assigneeIdsInput) {
    return null;
  }

  const { fullPath } = el.dataset;
  const currentUser = {
    id: gon?.current_user_id,
    username: gon?.current_username,
    name: gon?.current_user_fullname,
    avatarUrl: gon?.current_user_avatar_url,
  };

  return new Vue({
    el,
    apolloProvider,
    data() {
      return {
        selectedUserName: '',
        value: [],
      };
    },
    methods: {
      onSelectedUnassigned() {
        assigneeIdsInput.value = 0;
        this.value = [];
        this.selectedUserName = __('Unassigned');
      },
      onSelected(selected) {
        assigneeIdsInput.value = selected.map((user) => getIdFromGraphQLId(user.id));
        this.value = selected;
        this.selectedUserName = selected.map((user) => user.name).join(', ');
      },
    },
    render(h) {
      const component = this;

      return h(UserSelect, {
        props: {
          text: component.selectedUserName || __('Select assignee'),
          headerText: __('Select assignees'),
          fullPath,
          currentUser,
          value: component.value,
        },
        on: {
          input(selected) {
            if (!selected.length) {
              component.onSelectedUnassigned();
              return;
            }

            component.onSelected(selected);
          },
        },
        class: 'gl-w-full',
      });
    },
  });
}

export function mountSidebar(mediator, store, pinia) {
  mountSidebarTodoWidget();
  mountSidebarAssigneesWidget();
  mountSidebarReviewers(mediator);
  mountSidebarCrmContacts();
  mountSidebarLabelsWidget();
  mountSidebarMilestoneWidget();
  mountSidebarDueDateWidget();
  mountSidebarReferenceWidget();
  mountIssuableLockForm(store, pinia);
  mountSidebarParticipantsWidget();
  mountSidebarSubscriptionsWidget();
  mountCopyEmailToClipboard();
  mountSidebarTimeTracking();
  mountSidebarSeverityWidget();
  mountSidebarEscalationStatus();
  mountMoveIssueButton();
}

export { getSidebarOptions };
