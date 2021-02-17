import { IssuableType } from '~/issue_show/constants';
import getIssueParticipants from '~/vue_shared/components/sidebar/queries/get_issue_participants.query.graphql';
import getMergeRequestParticipants from '~/vue_shared/components/sidebar/queries/get_mr_participants.query.graphql';
import updateAssigneesMutation from '~/vue_shared/components/sidebar/queries/update_issue_assignees.mutation.graphql';
import updateMergeRequestParticipantsMutation from '~/vue_shared/components/sidebar/queries/update_mr_assignees.mutation.graphql';

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
