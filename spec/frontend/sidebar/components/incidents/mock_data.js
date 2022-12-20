import { STATUS_TRIGGERED, STATUS_ACKNOWLEDGED } from '~/sidebar/constants';

export const fetchData = {
  workspace: {
    __typename: 'Project',
    id: 'gid://gitlab/Project/2',
    issuable: {
      __typename: 'Issue',
      id: 'gid://gitlab/Issue/4',
      escalationStatus: STATUS_TRIGGERED,
    },
  },
};

export const mutationData = {
  issueSetEscalationStatus: {
    __typename: 'IssueSetEscalationStatusPayload',
    errors: [],
    clientMutationId: null,
    issue: {
      __typename: 'Issue',
      id: 'gid://gitlab/Issue/4',
      escalationStatus: STATUS_ACKNOWLEDGED,
    },
  },
};

export const fetchError = {
  workspace: {
    __typename: 'Project',
  },
};

export const mutationError = {
  issueSetEscalationStatus: {
    __typename: 'IssueSetEscalationStatusPayload',
    errors: ['hello'],
  },
};
