const createMockPlaceholderUser = (index) => ({
  __typename: 'UserCore',
  id: `gid://gitlab/User/382${index}`,
  avatarUrl: '/avatar1',
  name: `Placeholder ${index}`,
  username: `placeholder_${index}`,
  webUrl: '/',
  webPath: '/',
});

const createMockReassignedSourceUser = (index) => ({
  __typename: 'ImportSourceUser',
  id: `gid://gitlab/Import::SourceUser/${index}`,
  createdAt: '2024-09-17T00:41:28.000Z',
  status: 'COMPLETED',
  sourceHostname: 'https://gitlab.com',
  sourceName: `Old User ${index}`,
  sourceUsername: `old_user_${index}`,
  sourceUserIdentifier: `${index}`,
  placeholderUser: createMockPlaceholderUser(index),
  namespace: {
    __typename: 'Namespace',
    id: 'gid://gitlab/Group/1',
    fullPath: 'imported-group',
    webPath: '/groups/imported-group',
  },
});

export const mockReassignedSourceUsers = [
  createMockReassignedSourceUser(1),
  createMockReassignedSourceUser(2),
];

export const mockReassignedSourceUsersQueryResponse = ({
  nodes = mockReassignedSourceUsers,
  pageInfo = {},
} = {}) => ({
  data: {
    currentUser: {
      __typename: 'CurrentUser',
      id: 'gid://gitlab/User/1',
      importSourceUsers: {
        __typename: 'ImportSourceUserConnection',
        nodes,
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: 'start',
          endCursor: 'end',
          ...pageInfo,
        },
      },
    },
  },
});

export const mockRevokeMutationResponse = ({ errors = [] } = {}) => ({
  data: {
    importSourceUserRevoke: {
      __typename: 'ImportSourceUserRevokePayload',
      errors,
      importSourceUser: {
        __typename: 'ImportSourceUser',
        id: 'gid://gitlab/Import::SourceUser/1',
        status: 'PENDING_REASSIGNMENT',
      },
    },
  },
});
