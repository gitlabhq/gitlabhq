import { STATUS_TRIGGERED, STATUS_ACKNOWLEDGED } from '~/sidebar/constants';

export const fetchData = {
  namespace: {
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
  namespace: {
    __typename: 'Project',
  },
};

export const mutationError = {
  issueSetEscalationStatus: {
    __typename: 'IssueSetEscalationStatusPayload',
    errors: ['hello'],
  },
};
