import { IssuableType } from '~/issue_show/constants';
import epicConfidentialQuery from '~/sidebar/queries/epic_confidential.query.graphql';
import epicDueDateQuery from '~/sidebar/queries/epic_due_date.query.graphql';
import epicParticipantsQuery from '~/sidebar/queries/epic_participants.query.graphql';
import epicStartDateQuery from '~/sidebar/queries/epic_start_date.query.graphql';
import epicSubscribedQuery from '~/sidebar/queries/epic_subscribed.query.graphql';
import issuableAssigneesSubscription from '~/sidebar/queries/issuable_assignees.subscription.graphql';
import issueConfidentialQuery from '~/sidebar/queries/issue_confidential.query.graphql';
import issueDueDateQuery from '~/sidebar/queries/issue_due_date.query.graphql';
import issueReferenceQuery from '~/sidebar/queries/issue_reference.query.graphql';
import issueSubscribedQuery from '~/sidebar/queries/issue_subscribed.query.graphql';
import mergeRequestReferenceQuery from '~/sidebar/queries/merge_request_reference.query.graphql';
import mergeRequestSubscribed from '~/sidebar/queries/merge_request_subscribed.query.graphql';
import updateEpicConfidentialMutation from '~/sidebar/queries/update_epic_confidential.mutation.graphql';
import updateEpicDueDateMutation from '~/sidebar/queries/update_epic_due_date.mutation.graphql';
import updateEpicStartDateMutation from '~/sidebar/queries/update_epic_start_date.mutation.graphql';
import updateEpicSubscriptionMutation from '~/sidebar/queries/update_epic_subscription.mutation.graphql';
import updateIssueConfidentialMutation from '~/sidebar/queries/update_issue_confidential.mutation.graphql';
import updateIssueDueDateMutation from '~/sidebar/queries/update_issue_due_date.mutation.graphql';
import updateIssueSubscriptionMutation from '~/sidebar/queries/update_issue_subscription.mutation.graphql';
import updateMergeRequestSubscriptionMutation from '~/sidebar/queries/update_merge_request_subscription.mutation.graphql';
import getIssueAssignees from '~/vue_shared/components/sidebar/queries/get_issue_assignees.query.graphql';
import issueParticipantsQuery from '~/vue_shared/components/sidebar/queries/get_issue_participants.query.graphql';
import getIssueTimelogsQuery from '~/vue_shared/components/sidebar/queries/get_issue_timelogs.query.graphql';
import getMergeRequestAssignees from '~/vue_shared/components/sidebar/queries/get_mr_assignees.query.graphql';
import getMergeRequestParticipants from '~/vue_shared/components/sidebar/queries/get_mr_participants.query.graphql';
import getMrTimelogsQuery from '~/vue_shared/components/sidebar/queries/get_mr_timelogs.query.graphql';
import updateIssueAssigneesMutation from '~/vue_shared/components/sidebar/queries/update_issue_assignees.mutation.graphql';
import updateMergeRequestAssigneesMutation from '~/vue_shared/components/sidebar/queries/update_mr_assignees.mutation.graphql';

export const ASSIGNEES_DEBOUNCE_DELAY = 250;

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
