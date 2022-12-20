import { invert } from 'lodash';
import { s__, __, sprintf } from '~/locale';
import updateIssueLabelsMutation from '~/boards/graphql/issue_set_labels.mutation.graphql';
import userSearchQuery from '~/graphql_shared/queries/users_search.query.graphql';
import userSearchWithMRPermissionsQuery from '~/graphql_shared/queries/users_search_with_mr_permissions.graphql';
import { IssuableType, WorkspaceType } from '~/issues/constants';
import updateAlertAssigneesMutation from '~/vue_shared/alert_details/graphql/mutations/alert_set_assignees.mutation.graphql';
import epicLabelsQuery from './components/labels/labels_select_widget/graphql/epic_labels.query.graphql';
import updateEpicLabelsMutation from './components/labels/labels_select_widget/graphql/epic_update_labels.mutation.graphql';
import groupLabelsQuery from './components/labels/labels_select_widget/graphql/group_labels.query.graphql';
import issueLabelsQuery from './components/labels/labels_select_widget/graphql/issue_labels.query.graphql';
import mergeRequestLabelsQuery from './components/labels/labels_select_widget/graphql/merge_request_labels.query.graphql';
import projectLabelsQuery from './components/labels/labels_select_widget/graphql/project_labels.query.graphql';
import epicConfidentialQuery from './queries/epic_confidential.query.graphql';
import epicDueDateQuery from './queries/epic_due_date.query.graphql';
import epicParticipantsQuery from './queries/epic_participants.query.graphql';
import epicReferenceQuery from './queries/epic_reference.query.graphql';
import epicStartDateQuery from './queries/epic_start_date.query.graphql';
import epicSubscribedQuery from './queries/epic_subscribed.query.graphql';
import epicTodoQuery from './queries/epic_todo.query.graphql';
import issuableAssigneesSubscription from './queries/issuable_assignees.subscription.graphql';
import issueConfidentialQuery from './queries/issue_confidential.query.graphql';
import issueDueDateQuery from './queries/issue_due_date.query.graphql';
import issueReferenceQuery from './queries/issue_reference.query.graphql';
import issueSubscribedQuery from './queries/issue_subscribed.query.graphql';
import issueTimeTrackingQuery from './queries/issue_time_tracking.query.graphql';
import issueTodoQuery from './queries/issue_todo.query.graphql';
import mergeRequestMilestone from './queries/merge_request_milestone.query.graphql';
import mergeRequestReferenceQuery from './queries/merge_request_reference.query.graphql';
import mergeRequestSubscribed from './queries/merge_request_subscribed.query.graphql';
import mergeRequestTimeTrackingQuery from './queries/merge_request_time_tracking.query.graphql';
import mergeRequestTodoQuery from './queries/merge_request_todo.query.graphql';
import todoCreateMutation from './queries/todo_create.mutation.graphql';
import todoMarkDoneMutation from './queries/todo_mark_done.mutation.graphql';
import updateEpicConfidentialMutation from './queries/update_epic_confidential.mutation.graphql';
import updateEpicDueDateMutation from './queries/update_epic_due_date.mutation.graphql';
import updateEpicStartDateMutation from './queries/update_epic_start_date.mutation.graphql';
import updateEpicSubscriptionMutation from './queries/update_epic_subscription.mutation.graphql';
import updateIssueConfidentialMutation from './queries/update_issue_confidential.mutation.graphql';
import updateIssueDueDateMutation from './queries/update_issue_due_date.mutation.graphql';
import updateIssueSubscriptionMutation from './queries/update_issue_subscription.mutation.graphql';
import mergeRequestMilestoneMutation from './queries/update_merge_request_milestone.mutation.graphql';
import updateMergeRequestLabelsMutation from './queries/update_merge_request_labels.mutation.graphql';
import updateMergeRequestSubscriptionMutation from './queries/update_merge_request_subscription.mutation.graphql';
import getAlertAssignees from './queries/get_alert_assignees.query.graphql';
import getIssueAssignees from './queries/get_issue_assignees.query.graphql';
import issueParticipantsQuery from './queries/get_issue_participants.query.graphql';
import getIssueTimelogsQuery from './queries/get_issue_timelogs.query.graphql';
import getMergeRequestAssignees from './queries/get_mr_assignees.query.graphql';
import getMergeRequestParticipants from './queries/get_mr_participants.query.graphql';
import getMrTimelogsQuery from './queries/get_mr_timelogs.query.graphql';
import updateIssueAssigneesMutation from './queries/update_issue_assignees.mutation.graphql';
import updateMergeRequestAssigneesMutation from './queries/update_mr_assignees.mutation.graphql';
import getEscalationStatusQuery from './queries/escalation_status.query.graphql';
import updateEscalationStatusMutation from './queries/update_escalation_status.mutation.graphql';
import groupMilestonesQuery from './queries/group_milestones.query.graphql';
import projectIssueMilestoneMutation from './queries/project_issue_milestone.mutation.graphql';
import projectIssueMilestoneQuery from './queries/project_issue_milestone.query.graphql';
import projectMilestonesQuery from './queries/project_milestones.query.graphql';

export const defaultEpicSort = 'TITLE_ASC';

export const epicIidPattern = /^&(?<iid>\d+)$/;

export const assigneesQueries = {
  [IssuableType.Issue]: {
    query: getIssueAssignees,
    subscription: issuableAssigneesSubscription,
    mutation: updateIssueAssigneesMutation,
  },
  [IssuableType.MergeRequest]: {
    query: getMergeRequestAssignees,
    mutation: updateMergeRequestAssigneesMutation,
  },
  [IssuableType.Alert]: {
    query: getAlertAssignees,
    mutation: updateAlertAssigneesMutation,
  },
};

export const participantsQueries = {
  [IssuableType.Issue]: {
    query: issueParticipantsQuery,
  },
  [IssuableType.MergeRequest]: {
    query: getMergeRequestParticipants,
  },
  [IssuableType.Epic]: {
    query: epicParticipantsQuery,
  },
  [IssuableType.Alert]: {
    query: '',
    skipQuery: true,
  },
};

export const userSearchQueries = {
  [IssuableType.Issue]: {
    query: userSearchQuery,
  },
  [IssuableType.MergeRequest]: {
    query: userSearchWithMRPermissionsQuery,
  },
};

export const confidentialityQueries = {
  [IssuableType.Issue]: {
    query: issueConfidentialQuery,
    mutation: updateIssueConfidentialMutation,
  },
  [IssuableType.Epic]: {
    query: epicConfidentialQuery,
    mutation: updateEpicConfidentialMutation,
  },
};

export const referenceQueries = {
  [IssuableType.Issue]: {
    query: issueReferenceQuery,
  },
  [IssuableType.MergeRequest]: {
    query: mergeRequestReferenceQuery,
  },
  [IssuableType.Epic]: {
    query: epicReferenceQuery,
  },
};

export const workspaceLabelsQueries = {
  [WorkspaceType.project]: {
    query: projectLabelsQuery,
  },
  [WorkspaceType.group]: {
    query: groupLabelsQuery,
  },
};

export const issuableLabelsQueries = {
  [IssuableType.Issue]: {
    issuableQuery: issueLabelsQuery,
    mutation: updateIssueLabelsMutation,
    mutationName: 'updateIssue',
  },
  [IssuableType.MergeRequest]: {
    issuableQuery: mergeRequestLabelsQuery,
    mutation: updateMergeRequestLabelsMutation,
    mutationName: 'mergeRequestSetLabels',
  },
  [IssuableType.Epic]: {
    issuableQuery: epicLabelsQuery,
    mutation: updateEpicLabelsMutation,
    mutationName: 'updateEpic',
  },
};

export const dateTypes = {
  start: 'startDate',
  due: 'dueDate',
};

export const dateFields = {
  [dateTypes.start]: {
    isDateFixed: 'startDateIsFixed',
    dateFixed: 'startDateFixed',
    dateFromMilestones: 'startDateFromMilestones',
  },
  [dateTypes.due]: {
    isDateFixed: 'dueDateIsFixed',
    dateFixed: 'dueDateFixed',
    dateFromMilestones: 'dueDateFromMilestones',
  },
};

export const subscribedQueries = {
  [IssuableType.Issue]: {
    query: issueSubscribedQuery,
    mutation: updateIssueSubscriptionMutation,
  },
  [IssuableType.Epic]: {
    query: epicSubscribedQuery,
    mutation: updateEpicSubscriptionMutation,
  },
  [IssuableType.MergeRequest]: {
    query: mergeRequestSubscribed,
    mutation: updateMergeRequestSubscriptionMutation,
  },
};

export const Tracking = {
  editEvent: 'click_edit_button',
  rightSidebarLabel: 'right_sidebar',
};

export const timeTrackingQueries = {
  [IssuableType.Issue]: {
    query: issueTimeTrackingQuery,
  },
  [IssuableType.MergeRequest]: {
    query: mergeRequestTimeTrackingQuery,
  },
};

export const dueDateQueries = {
  [IssuableType.Issue]: {
    query: issueDueDateQuery,
    mutation: updateIssueDueDateMutation,
  },
  [IssuableType.Epic]: {
    query: epicDueDateQuery,
    mutation: updateEpicDueDateMutation,
  },
};

export const startDateQueries = {
  [IssuableType.Epic]: {
    query: epicStartDateQuery,
    mutation: updateEpicStartDateMutation,
  },
};

export const timelogQueries = {
  [IssuableType.Issue]: {
    query: getIssueTimelogsQuery,
  },
  [IssuableType.MergeRequest]: {
    query: getMrTimelogsQuery,
  },
};

export const noAttributeId = null;

export const issuableMilestoneQueries = {
  [IssuableType.Issue]: {
    query: projectIssueMilestoneQuery,
    mutation: projectIssueMilestoneMutation,
  },
  [IssuableType.MergeRequest]: {
    query: mergeRequestMilestone,
    mutation: mergeRequestMilestoneMutation,
  },
};

export const milestonesQueries = {
  [IssuableType.Issue]: {
    query: {
      [WorkspaceType.group]: groupMilestonesQuery,
      [WorkspaceType.project]: projectMilestonesQuery,
    },
  },
  [IssuableType.MergeRequest]: {
    query: {
      [WorkspaceType.group]: groupMilestonesQuery,
      [WorkspaceType.project]: projectMilestonesQuery,
    },
  },
};

export const IssuableAttributeType = {
  Milestone: 'milestone',
};

export const LocalizedIssuableAttributeType = {
  Milestone: s__('Issuable|milestone'),
};

export const IssuableAttributeTypeKeyMap = invert(IssuableAttributeType);

export const IssuableAttributeState = {
  [IssuableAttributeType.Milestone]: 'active',
};

export const issuableAttributesQueries = {
  [IssuableAttributeType.Milestone]: {
    current: issuableMilestoneQueries,
    list: milestonesQueries,
  },
};

export const todoQueries = {
  [IssuableType.Epic]: {
    query: epicTodoQuery,
  },
  [IssuableType.Issue]: {
    query: issueTodoQuery,
  },
  [IssuableType.MergeRequest]: {
    query: mergeRequestTodoQuery,
  },
};

export const TodoMutationTypes = {
  Create: 'create',
  MarkDone: 'mark-done',
};

export const todoMutations = {
  [TodoMutationTypes.Create]: todoCreateMutation,
  [TodoMutationTypes.MarkDone]: todoMarkDoneMutation,
};

export function dropdowni18nText(issuableAttribute, issuableType) {
  return {
    noAttribute: sprintf(s__('DropdownWidget|No %{issuableAttribute}'), {
      issuableAttribute,
    }),
    assignAttribute: sprintf(s__('DropdownWidget|Assign %{issuableAttribute}'), {
      issuableAttribute,
    }),
    noAttributesFound: sprintf(s__('DropdownWidget|No %{issuableAttribute} found'), {
      issuableAttribute,
    }),
    updateError: sprintf(
      s__(
        'DropdownWidget|Failed to set %{issuableAttribute} on this %{issuableType}. Please try again.',
      ),
      { issuableAttribute, issuableType },
    ),
    listFetchError: sprintf(
      s__(
        'DropdownWidget|Failed to fetch the %{issuableAttribute} for this %{issuableType}. Please try again.',
      ),
      { issuableAttribute, issuableType },
    ),
    currentFetchError: sprintf(
      s__(
        'DropdownWidget|An error occurred while fetching the assigned %{issuableAttribute} of the selected %{issuableType}.',
      ),
      { issuableAttribute, issuableType },
    ),
    noPermissionToView: sprintf(
      s__("DropdownWidget|You don't have permission to view this %{issuableAttribute}."),
      { issuableAttribute },
    ),
    editConfirmation: sprintf(
      s__(
        'DropdownWidget|You do not have permission to view the currently assigned %{issuableAttribute} and will not be able to choose it again if you reassign it.',
      ),
      {
        issuableAttribute,
      },
    ),
    editConfirmationCta: sprintf(s__('DropdownWidget|Edit %{issuableAttribute}'), {
      issuableAttribute,
    }),
    editConfirmationCancel: s__('DropdownWidget|Cancel'),
  };
}

export const escalationStatusQuery = getEscalationStatusQuery;
export const escalationStatusMutation = updateEscalationStatusMutation;

export const HOW_TO_TRACK_TIME = __('How to track time');

export const statusDropdownOptions = [
  {
    text: __('Open'),
    value: 'reopen',
  },
  {
    text: __('Closed'),
    value: 'close',
  },
];

export const subscriptionsDropdownOptions = [
  {
    text: __('Subscribe'),
    value: 'subscribe',
  },
  {
    text: __('Unsubscribe'),
    value: 'unsubscribe',
  },
];

export const INCIDENT_SEVERITY = {
  CRITICAL: {
    value: 'CRITICAL',
    icon: 'critical',
    label: s__('IncidentManagement|Critical - S1'),
  },
  HIGH: {
    value: 'HIGH',
    icon: 'high',
    label: s__('IncidentManagement|High - S2'),
  },
  MEDIUM: {
    value: 'MEDIUM',
    icon: 'medium',
    label: s__('IncidentManagement|Medium - S3'),
  },
  LOW: {
    value: 'LOW',
    icon: 'low',
    label: s__('IncidentManagement|Low - S4'),
  },
  UNKNOWN: {
    value: 'UNKNOWN',
    icon: 'unknown',
    label: s__('IncidentManagement|Unknown'),
  },
};

export const ISSUABLE_TYPES = {
  INCIDENT: 'incident',
};

export const MILESTONE_STATE = {
  ACTIVE: 'active',
  CLOSED: 'closed',
};

export const SEVERITY_I18N = {
  UPDATE_SEVERITY_ERROR: s__('SeverityWidget|There was an error while updating severity.'),
  TRY_AGAIN: __('Please try again'),
  EDIT: __('Edit'),
  SEVERITY: s__('SeverityWidget|Severity'),
  SEVERITY_VALUE: s__('SeverityWidget|Severity: %{severity}'),
};

export const STATUS_TRIGGERED = 'TRIGGERED';
export const STATUS_ACKNOWLEDGED = 'ACKNOWLEDGED';
export const STATUS_RESOLVED = 'RESOLVED';

export const STATUS_TRIGGERED_LABEL = s__('IncidentManagement|Triggered');
export const STATUS_ACKNOWLEDGED_LABEL = s__('IncidentManagement|Acknowledged');
export const STATUS_RESOLVED_LABEL = s__('IncidentManagement|Resolved');

export const STATUS_LABELS = {
  [STATUS_TRIGGERED]: STATUS_TRIGGERED_LABEL,
  [STATUS_ACKNOWLEDGED]: STATUS_ACKNOWLEDGED_LABEL,
  [STATUS_RESOLVED]: STATUS_RESOLVED_LABEL,
};

export const INCIDENTS_I18N = {
  fetchError: s__(
    'IncidentManagement|An error occurred while fetching the incident status. Please reload the page.',
  ),
  title: s__('IncidentManagement|Status'),
  updateError: s__(
    'IncidentManagement|An error occurred while updating the incident status. Please reload the page and try again.',
  ),
};
