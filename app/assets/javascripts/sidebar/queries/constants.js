import updateIssueLabelsMutation from '~/boards/graphql/issue_set_labels.mutation.graphql';
import userAutocompleteQuery from '~/graphql_shared/queries/workspace_autocomplete_users.query.graphql';
import userAutocompleteWithMRPermissionsQuery from '~/graphql_shared/queries/project_autocomplete_users_with_mr_permissions.query.graphql';
import issuableDatesUpdatedSubscription from '~/graphql_shared/subscriptions/work_item_dates.subscription.graphql';
import {
  TYPE_ALERT,
  TYPE_EPIC,
  TYPE_INCIDENT,
  TYPE_ISSUE,
  TYPE_MERGE_REQUEST,
  TYPE_TEST_CASE,
  WORKSPACE_GROUP,
  WORKSPACE_PROJECT,
} from '~/issues/constants';
import updateAlertAssigneesMutation from '~/vue_shared/alert_details/graphql/mutations/alert_set_assignees.mutation.graphql';
import abuseReportLabelsQuery from '~/admin/abuse_report/graphql/abuse_report_labels.query.graphql';
import createAbuseReportLabelMutation from '~/admin/abuse_report/graphql/create_abuse_report_label.mutation.graphql';
import createGroupOrProjectLabelMutation from '../components/labels/labels_select_widget/graphql/create_label.mutation.graphql';
import updateTestCaseLabelsMutation from '../components/labels/labels_select_widget/graphql/update_test_case_labels.mutation.graphql';
import epicLabelsQuery from '../components/labels/labels_select_widget/graphql/epic_labels.query.graphql';
import updateEpicLabelsMutation from '../components/labels/labels_select_widget/graphql/epic_update_labels.mutation.graphql';
import groupLabelsQuery from '../components/labels/labels_select_widget/graphql/group_labels.query.graphql';
import issueLabelsQuery from '../components/labels/labels_select_widget/graphql/issue_labels.query.graphql';
import mergeRequestLabelsQuery from '../components/labels/labels_select_widget/graphql/merge_request_labels.query.graphql';
import projectLabelsQuery from '../components/labels/labels_select_widget/graphql/project_labels.query.graphql';
import { IssuableAttributeType, todoMutationTypes } from '../constants';
import epicConfidentialQuery from './epic_confidential.query.graphql';
import epicDueDateQuery from './epic_due_date.query.graphql';
import epicParticipantsQuery from './epic_participants.query.graphql';
import epicReferenceQuery from './epic_reference.query.graphql';
import epicStartDateQuery from './epic_start_date.query.graphql';
import epicSubscribedQuery from './epic_subscribed.query.graphql';
import epicTodoQuery from './epic_todo.query.graphql';
import issuableAssigneesSubscription from './issuable_assignees.subscription.graphql';
import issueConfidentialQuery from './issue_confidential.query.graphql';
import issueDueDateQuery from './issue_due_date.query.graphql';
import issueReferenceQuery from './issue_reference.query.graphql';
import issueSubscribedQuery from './issue_subscribed.query.graphql';
import issueTimeTrackingQuery from './issue_time_tracking.query.graphql';
import issueTodoQuery from './issue_todo.query.graphql';
import mergeRequestMilestone from './merge_request_milestone.query.graphql';
import mergeRequestReferenceQuery from './merge_request_reference.query.graphql';
import mergeRequestSubscribed from './merge_request_subscribed.query.graphql';
import mergeRequestTimeTrackingQuery from './merge_request_time_tracking.query.graphql';
import mergeRequestTodoQuery from './merge_request_todo.query.graphql';
import mergeRequestTodoSubscription from './merge_request_todo.subscription.graphql';
import todoCreateMutation from './todo_create.mutation.graphql';
import todoMarkDoneMutation from './todo_mark_done.mutation.graphql';
import updateEpicConfidentialMutation from './update_epic_confidential.mutation.graphql';
import updateEpicDueDateMutation from './update_epic_due_date.mutation.graphql';
import updateEpicStartDateMutation from './update_epic_start_date.mutation.graphql';
import updateEpicSubscriptionMutation from './update_epic_subscription.mutation.graphql';
import updateIssueConfidentialMutation from './update_issue_confidential.mutation.graphql';
import updateIssueDueDateMutation from './update_issue_due_date.mutation.graphql';
import updateIssueSubscriptionMutation from './update_issue_subscription.mutation.graphql';
import mergeRequestMilestoneMutation from './update_merge_request_milestone.mutation.graphql';
import updateMergeRequestLabelsMutation from './update_merge_request_labels.mutation.graphql';
import updateMergeRequestSubscriptionMutation from './update_merge_request_subscription.mutation.graphql';
import getAlertAssignees from './get_alert_assignees.query.graphql';
import getIssueAssignees from './get_issue_assignees.query.graphql';
import issueParticipantsQuery from './get_issue_participants.query.graphql';
import getIssueTimelogsQuery from './get_issue_timelogs.query.graphql';
import getMergeRequestAssignees from './get_mr_assignees.query.graphql';
import getMergeRequestParticipants from './get_mr_participants.query.graphql';
import getMrTimelogsQuery from './get_mr_timelogs.query.graphql';
import updateIssueAssigneesMutation from './update_issue_assignees.mutation.graphql';
import updateMergeRequestAssigneesMutation from './update_mr_assignees.mutation.graphql';
import getEscalationStatusQuery from './escalation_status.query.graphql';
import updateEscalationStatusMutation from './update_escalation_status.mutation.graphql';
import groupMilestonesQuery from './group_milestones.query.graphql';
import projectIssueMilestoneMutation from './project_issue_milestone.mutation.graphql';
import projectIssueMilestoneQuery from './project_issue_milestone.query.graphql';
import projectMilestonesQuery from './project_milestones.query.graphql';
import testCaseConfidentialQuery from './test_case_confidential.query.graphql';
import updateTestCaseConfidentialMutation from './update_test_case_confidential.mutation.graphql';

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
    query: userAutocompleteQuery,
  },
  [TYPE_MERGE_REQUEST]: {
    query: userAutocompleteWithMRPermissionsQuery,
  },
};

export const confidentialityQueries = {
  [TYPE_INCIDENT]: {
    query: issueConfidentialQuery,
    mutation: updateIssueConfidentialMutation,
  },
  [TYPE_ISSUE]: {
    query: issueConfidentialQuery,
    mutation: updateIssueConfidentialMutation,
  },
  [TYPE_EPIC]: {
    query: epicConfidentialQuery,
    mutation: updateEpicConfidentialMutation,
  },
  [TYPE_TEST_CASE]: {
    query: testCaseConfidentialQuery,
    mutation: updateTestCaseConfidentialMutation,
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
    dataPath: 'workspace.labels',
  },
  [WORKSPACE_GROUP]: {
    query: groupLabelsQuery,
    dataPath: 'workspace.labels',
  },
  abuseReport: {
    query: abuseReportLabelsQuery,
    dataPath: 'labels',
  },
};

export const workspaceCreateLabelMutation = {
  [WORKSPACE_PROJECT]: createGroupOrProjectLabelMutation,
  [WORKSPACE_GROUP]: createGroupOrProjectLabelMutation,
  abuseReport: createAbuseReportLabelMutation,
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
    subscription: mergeRequestTodoSubscription,
  },
};

export const todoMutations = {
  [todoMutationTypes.create]: todoCreateMutation,
  [todoMutationTypes.markDone]: todoMarkDoneMutation,
};

export const escalationStatusQuery = getEscalationStatusQuery;

export const escalationStatusMutation = updateEscalationStatusMutation;
