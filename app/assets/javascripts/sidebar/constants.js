import { invert } from 'lodash';
import { s__, __, sprintf } from '~/locale';
import updateIssueLabelsMutation from '~/boards/graphql/issue_set_labels.mutation.graphql';
import userSearchQuery from '~/graphql_shared/queries/users_search.query.graphql';
import userSearchWithMRPermissionsQuery from '~/graphql_shared/queries/users_search_with_mr_permissions.graphql';
import {
  TYPE_ALERT,
  TYPE_EPIC,
  TYPE_ISSUE,
  TYPE_MERGE_REQUEST,
  TYPE_TEST_CASE,
  WORKSPACE_GROUP,
  WORKSPACE_PROJECT,
} from '~/issues/constants';
import updateAlertAssigneesMutation from '~/vue_shared/alert_details/graphql/mutations/alert_set_assignees.mutation.graphql';
import issuableDatesUpdatedSubscription from '../graphql_shared/subscriptions/work_item_dates.subscription.graphql';
import updateTestCaseLabelsMutation from './components/labels/labels_select_widget/graphql/update_test_case_labels.mutation.graphql';
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
  [TYPE_ISSUE]: {
    query: getIssueAssignees,
    subscription: issuableAssigneesSubscription,
    mutation: updateIssueAssigneesMutation,
  },
  [TYPE_MERGE_REQUEST]: {
    query: getMergeRequestAssignees,
    mutation: updateMergeRequestAssigneesMutation,
  },
  [TYPE_ALERT]: {
    query: getAlertAssignees,
    mutation: updateAlertAssigneesMutation,
  },
};

export const participantsQueries = {
  [TYPE_ISSUE]: {
    query: issueParticipantsQuery,
  },
  [TYPE_MERGE_REQUEST]: {
    query: getMergeRequestParticipants,
  },
  [TYPE_EPIC]: {
    query: epicParticipantsQuery,
  },
  [TYPE_ALERT]: {
    query: '',
    skipQuery: true,
  },
};

export const userSearchQueries = {
  [TYPE_ISSUE]: {
    query: userSearchQuery,
  },
  [TYPE_MERGE_REQUEST]: {
    query: userSearchWithMRPermissionsQuery,
  },
};

export const confidentialityQueries = {
  [TYPE_ISSUE]: {
    query: issueConfidentialQuery,
    mutation: updateIssueConfidentialMutation,
  },
  [TYPE_EPIC]: {
    query: epicConfidentialQuery,
    mutation: updateEpicConfidentialMutation,
  },
};

export const referenceQueries = {
  [TYPE_ISSUE]: {
    query: issueReferenceQuery,
  },
  [TYPE_MERGE_REQUEST]: {
    query: mergeRequestReferenceQuery,
  },
  [TYPE_EPIC]: {
    query: epicReferenceQuery,
  },
};

export const workspaceLabelsQueries = {
  [WORKSPACE_PROJECT]: {
    query: projectLabelsQuery,
  },
  [WORKSPACE_GROUP]: {
    query: groupLabelsQuery,
  },
};

export const issuableLabelsQueries = {
  [TYPE_ISSUE]: {
    issuableQuery: issueLabelsQuery,
    mutation: updateIssueLabelsMutation,
    mutationName: 'updateIssue',
  },
  [TYPE_MERGE_REQUEST]: {
    issuableQuery: mergeRequestLabelsQuery,
    mutation: updateMergeRequestLabelsMutation,
    mutationName: 'mergeRequestSetLabels',
  },
  [TYPE_EPIC]: {
    issuableQuery: epicLabelsQuery,
    mutation: updateEpicLabelsMutation,
    mutationName: 'updateEpic',
  },
  [TYPE_TEST_CASE]: {
    issuableQuery: issueLabelsQuery,
    mutation: updateTestCaseLabelsMutation,
    mutationName: 'updateTestCaseLabels',
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
  [TYPE_ISSUE]: {
    query: issueSubscribedQuery,
    mutation: updateIssueSubscriptionMutation,
  },
  [TYPE_EPIC]: {
    query: epicSubscribedQuery,
    mutation: updateEpicSubscriptionMutation,
  },
  [TYPE_MERGE_REQUEST]: {
    query: mergeRequestSubscribed,
    mutation: updateMergeRequestSubscriptionMutation,
  },
};

export const Tracking = {
  editEvent: 'click_edit_button',
  rightSidebarLabel: 'right_sidebar',
};

export const timeTrackingQueries = {
  [TYPE_ISSUE]: {
    query: issueTimeTrackingQuery,
  },
  [TYPE_MERGE_REQUEST]: {
    query: mergeRequestTimeTrackingQuery,
  },
};

export const dueDateQueries = {
  [TYPE_ISSUE]: {
    query: issueDueDateQuery,
    mutation: updateIssueDueDateMutation,
    subscription: issuableDatesUpdatedSubscription,
  },
  [TYPE_EPIC]: {
    query: epicDueDateQuery,
    mutation: updateEpicDueDateMutation,
  },
};

export const startDateQueries = {
  [TYPE_EPIC]: {
    query: epicStartDateQuery,
    mutation: updateEpicStartDateMutation,
  },
};

export const timelogQueries = {
  [TYPE_ISSUE]: {
    query: getIssueTimelogsQuery,
  },
  [TYPE_MERGE_REQUEST]: {
    query: getMrTimelogsQuery,
  },
};

export const noAttributeId = null;

export const issuableMilestoneQueries = {
  [TYPE_ISSUE]: {
    query: projectIssueMilestoneQuery,
    mutation: projectIssueMilestoneMutation,
  },
  [TYPE_MERGE_REQUEST]: {
    query: mergeRequestMilestone,
    mutation: mergeRequestMilestoneMutation,
  },
};

export const milestonesQueries = {
  [TYPE_ISSUE]: {
    query: {
      [WORKSPACE_GROUP]: groupMilestonesQuery,
      [WORKSPACE_PROJECT]: projectMilestonesQuery,
    },
  },
  [TYPE_MERGE_REQUEST]: {
    query: {
      [WORKSPACE_GROUP]: groupMilestonesQuery,
      [WORKSPACE_PROJECT]: projectMilestonesQuery,
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
  [TYPE_EPIC]: {
    query: epicTodoQuery,
  },
  [TYPE_ISSUE]: {
    query: issueTodoQuery,
  },
  [TYPE_MERGE_REQUEST]: {
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
