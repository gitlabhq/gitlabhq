import { IssuableType } from '~/issue_show/constants';
import epicConfidentialQuery from '~/sidebar/queries/epic_confidential.query.graphql';
import issueConfidentialQuery from '~/sidebar/queries/issue_confidential.query.graphql';
import issueDueDateQuery from '~/sidebar/queries/issue_due_date.query.graphql';
import issueReferenceQuery from '~/sidebar/queries/issue_reference.query.graphql';
import mergeRequestReferenceQuery from '~/sidebar/queries/merge_request_reference.query.graphql';
import updateEpicMutation from '~/sidebar/queries/update_epic_confidential.mutation.graphql';
import updateIssueConfidentialMutation from '~/sidebar/queries/update_issue_confidential.mutation.graphql';
import updateIssueDueDateMutation from '~/sidebar/queries/update_issue_due_date.mutation.graphql';
import getIssueParticipants from '~/vue_shared/components/sidebar/queries/get_issue_participants.query.graphql';
import getMergeRequestParticipants from '~/vue_shared/components/sidebar/queries/get_mr_participants.query.graphql';
import updateAssigneesMutation from '~/vue_shared/components/sidebar/queries/update_issue_assignees.mutation.graphql';
import updateMergeRequestParticipantsMutation from '~/vue_shared/components/sidebar/queries/update_mr_assignees.mutation.graphql';

export const ASSIGNEES_DEBOUNCE_DELAY = 250;

export const assigneesQueries = {
  [IssuableType.Issue]: {
    query: getIssueParticipants,
    mutation: updateAssigneesMutation,
  },
  [IssuableType.MergeRequest]: {
    query: getMergeRequestParticipants,
    mutation: updateMergeRequestParticipantsMutation,
  },
};

export const confidentialityQueries = {
  [IssuableType.Issue]: {
    query: issueConfidentialQuery,
    mutation: updateIssueConfidentialMutation,
  },
  [IssuableType.Epic]: {
    query: epicConfidentialQuery,
    mutation: updateEpicMutation,
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

export const dueDateQueries = {
  [IssuableType.Issue]: {
    query: issueDueDateQuery,
    mutation: updateIssueDueDateMutation,
  },
};
