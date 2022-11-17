import { invert } from 'lodash';
import { s__, __, sprintf } from '~/locale';
import updateIssueLabelsMutation from '~/boards/graphql/issue_set_labels.mutation.graphql';
import userSearchQuery from '~/graphql_shared/queries/users_search.query.graphql';
import userSearchWithMRPermissionsQuery from '~/graphql_shared/queries/users_search_with_mr_permissions.graphql';
import { IssuableType, WorkspaceType } from '~/issues/constants';
import epicConfidentialQuery from '~/sidebar/queries/epic_confidential.query.graphql';
import epicDueDateQuery from '~/sidebar/queries/epic_due_date.query.graphql';
import epicParticipantsQuery from '~/sidebar/queries/epic_participants.query.graphql';
import epicReferenceQuery from '~/sidebar/queries/epic_reference.query.graphql';
import epicStartDateQuery from '~/sidebar/queries/epic_start_date.query.graphql';
import epicSubscribedQuery from '~/sidebar/queries/epic_subscribed.query.graphql';
import epicTodoQuery from '~/sidebar/queries/epic_todo.query.graphql';
import issuableAssigneesSubscription from '~/sidebar/queries/issuable_assignees.subscription.graphql';
import issueConfidentialQuery from '~/sidebar/queries/issue_confidential.query.graphql';
import issueDueDateQuery from '~/sidebar/queries/issue_due_date.query.graphql';
import issueReferenceQuery from '~/sidebar/queries/issue_reference.query.graphql';
import issueSubscribedQuery from '~/sidebar/queries/issue_subscribed.query.graphql';
import issueTimeTrackingQuery from '~/sidebar/queries/issue_time_tracking.query.graphql';
import issueTodoQuery from '~/sidebar/queries/issue_todo.query.graphql';
import mergeRequestMilestone from '~/sidebar/queries/merge_request_milestone.query.graphql';
import mergeRequestReferenceQuery from '~/sidebar/queries/merge_request_reference.query.graphql';
import mergeRequestSubscribed from '~/sidebar/queries/merge_request_subscribed.query.graphql';
import mergeRequestTimeTrackingQuery from '~/sidebar/queries/merge_request_time_tracking.query.graphql';
import mergeRequestTodoQuery from '~/sidebar/queries/merge_request_todo.query.graphql';
import todoCreateMutation from '~/sidebar/queries/todo_create.mutation.graphql';
import todoMarkDoneMutation from '~/sidebar/queries/todo_mark_done.mutation.graphql';
import updateEpicConfidentialMutation from '~/sidebar/queries/update_epic_confidential.mutation.graphql';
import updateEpicDueDateMutation from '~/sidebar/queries/update_epic_due_date.mutation.graphql';
import updateEpicStartDateMutation from '~/sidebar/queries/update_epic_start_date.mutation.graphql';
import updateEpicSubscriptionMutation from '~/sidebar/queries/update_epic_subscription.mutation.graphql';
import updateIssueConfidentialMutation from '~/sidebar/queries/update_issue_confidential.mutation.graphql';
import updateIssueDueDateMutation from '~/sidebar/queries/update_issue_due_date.mutation.graphql';
import updateIssueSubscriptionMutation from '~/sidebar/queries/update_issue_subscription.mutation.graphql';
import mergeRequestMilestoneMutation from '~/sidebar/queries/update_merge_request_milestone.mutation.graphql';
import updateMergeRequestLabelsMutation from '~/sidebar/queries/update_merge_request_labels.mutation.graphql';
import updateMergeRequestSubscriptionMutation from '~/sidebar/queries/update_merge_request_subscription.mutation.graphql';
import updateAlertAssigneesMutation from '~/vue_shared/alert_details/graphql/mutations/alert_set_assignees.mutation.graphql';
import epicLabelsQuery from '~/vue_shared/components/sidebar/labels_select_widget/graphql/epic_labels.query.graphql';
import updateEpicLabelsMutation from '~/vue_shared/components/sidebar/labels_select_widget/graphql/epic_update_labels.mutation.graphql';
import groupLabelsQuery from '~/vue_shared/components/sidebar/labels_select_widget/graphql/group_labels.query.graphql';
import issueLabelsQuery from '~/vue_shared/components/sidebar/labels_select_widget/graphql/issue_labels.query.graphql';
import mergeRequestLabelsQuery from '~/vue_shared/components/sidebar/labels_select_widget/graphql/merge_request_labels.query.graphql';
import projectLabelsQuery from '~/vue_shared/components/sidebar/labels_select_widget/graphql/project_labels.query.graphql';
import getAlertAssignees from '~/vue_shared/components/sidebar/queries/get_alert_assignees.query.graphql';
import getIssueAssignees from '~/vue_shared/components/sidebar/queries/get_issue_assignees.query.graphql';
import issueParticipantsQuery from '~/vue_shared/components/sidebar/queries/get_issue_participants.query.graphql';
import getIssueTimelogsQuery from '~/vue_shared/components/sidebar/queries/get_issue_timelogs.query.graphql';
import getMergeRequestAssignees from '~/vue_shared/components/sidebar/queries/get_mr_assignees.query.graphql';
import getMergeRequestParticipants from '~/vue_shared/components/sidebar/queries/get_mr_participants.query.graphql';
import getMrTimelogsQuery from '~/vue_shared/components/sidebar/queries/get_mr_timelogs.query.graphql';
import updateIssueAssigneesMutation from '~/vue_shared/components/sidebar/queries/update_issue_assignees.mutation.graphql';
import updateMergeRequestAssigneesMutation from '~/vue_shared/components/sidebar/queries/update_mr_assignees.mutation.graphql';
import getEscalationStatusQuery from '~/sidebar/queries/escalation_status.query.graphql';
import updateEscalationStatusMutation from '~/sidebar/queries/update_escalation_status.mutation.graphql';
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
