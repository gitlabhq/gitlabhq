const createMockPlaceholderUser = (index) => {
  return {
    __typename: 'UserCore',
    id: `gid://gitlab/User/382${index}`,
    avatarUrl: '/avatar1',
    name: `Placeholder ${index}`,
    username: `placeholder_${index}`,
    webUrl: '/',
    webPath: '/',
  };
};

const createMockReassignUser = (index) => {
  return {
    __typename: 'UserCore',
    id: `gid://gitlab/User/741${index}`,
    avatarUrl: '/avatar2',
    name: `Reassigned ${index}`,
    username: `reassigned_${index}`,
    webUrl: '/',
    webPath: '/',
  };
};

const createMockSourceUser = (
  index,
  { status, placeholderUser = true, reassignToUser = false, sourceUserExists = true } = {},
) => {
  return {
    __typename: 'ImportSourceUser',
    id: `gid://gitlab/Import::SourceUser/${index}`,
    sourceHostname: 'https://gitlab.com',
    sourceName: sourceUserExists ? `Old User ${index}` : null,
    sourceUsername: sourceUserExists ? `old_user_${index}` : null,
    sourceUserIdentifier: index,
    status,
    reassignmentError: null,
    placeholderUser: placeholderUser ? createMockPlaceholderUser(index) : null,
    reassignToUser: reassignToUser ? createMockReassignUser(index) : null,
  };
};

export const mockSourceUsers = [
  createMockSourceUser(1, {
    status: 'PENDING_REASSIGNMENT',
  }),
  createMockSourceUser(2, {
    status: 'AWAITING_APPROVAL',
    reassignToUser: true,
  }),
  createMockSourceUser(3, {
    status: 'REJECTED',
  }),
  createMockSourceUser(4, {
    status: 'REASSIGNMENT_IN_PROGRESS',
    reassignToUser: true,
  }),
  createMockSourceUser(5, {
    status: 'FAILED',
    reassignToUser: true,
  }),
  createMockSourceUser(6, {
    status: 'KEEP_AS_PLACEHOLDER',
  }),
  createMockSourceUser(7, {
    status: 'COMPLETED',
    placeholderUser: false,
    reassignToUser: true,
    sourceUserExists: false,
  }),
];

export const mockSourceUsersQueryResponse = ({ nodes = mockSourceUsers, pageInfo = {} } = {}) => ({
  data: {
    namespace: {
      __typename: 'Namespace',
      id: 'gid://gitlab/Group/1',
      importSourceUsers: {
        __typename: 'ImportSourceUserConnection',
        nodes,
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: '',
          endCursor: '',
          ...pageInfo,
        },
      },
    },
  },
});

export const mockReassignMutationResponse = {
  data: {
    importSourceUserReassign: {
      errors: [],
      importSourceUser: {
        ...mockSourceUsers[0],
        status: 'AWAITING_APPROVAL',
        reassignToUser: createMockReassignUser(1),
      },
      __typename: 'ImportSourceUserReassignPayload',
    },
  },
};
export const mockKeepAsPlaceholderMutationResponse = {
  data: {
    importSourceUserKeepAsPlaceholder: {
      errors: [],
      importSourceUser: {
        ...mockSourceUsers[0],
        status: 'KEEP_AS_PLACEHOLDER',
      },
      __typename: 'ImportSourceUserKeepAsPlaceholderPayload',
    },
  },
};
export const mockResendNotificationMutationResponse = {
  data: {
    importSourceUserResendNotification: {
      errors: [],
      importSourceUser: {
        ...mockSourceUsers[0],
        status: 'AWAITING_APPROVAL',
        reassignToUser: createMockReassignUser(1),
      },
      __typename: 'ImportSourceUserResendNotificationPayload',
    },
  },
};
export const mockCancelReassignmentMutationResponse = {
  data: {
    importSourceUserCancelReassignment: {
      errors: [],
      importSourceUser: {
        ...mockSourceUsers[0],
        status: 'PENDING_REASSIGNMENT',
      },
      __typename: 'ImportSourceUserCancelReassignmentPayload',
    },
  },
};
export const mockKeepAllAsPlaceholderMutationResponse = {
  data: {
    importSourceUserKeepAllAsPlaceholder: {
      errors: [],
      updatedImportSourceUserCount: 1,
      __typename: 'ImportSourceUserKeepAllAsPlaceholderPayload',
    },
  },
};

export const mockUser1 = {
  __typename: 'UserCore',
  id: 'gid://gitlab/User/1',
  avatarUrl: '/avatar1',
  name: 'Administrator',
  username: 'root',
  webUrl: '/root',
  webPath: '/root',
};

export const mockUser2 = {
  __typename: 'UserCore',
  id: 'gid://gitlab/User/2',
  avatarUrl: '/avatar2',
  name: 'Rookie',
  username: 'rookie',
  webUrl: '/rookie',
  webPath: '/rookie',
};

export const mockUsersQueryResponse = {
  data: {
    users: {
      __typename: 'UserCoreConnection',
      nodes: [mockUser1],
      pageInfo: {
        __typename: 'PageInfo',
        hasNextPage: false,
        hasPreviousPage: false,
        startCursor: '',
        endCursor: 'end456',
      },
    },
  },
};

export const mockUsersWithPaginationQueryResponse = {
  data: {
    users: {
      __typename: 'UserCoreConnection',
      nodes: [mockUser2],
      pageInfo: {
        __typename: 'PageInfo',
        hasNextPage: true,
        hasPreviousPage: false,
        startCursor: '',
        endCursor: 'end123',
      },
    },
  },
};

export const pagination = {
  awaitingReassignmentItems: 5,
  reassignedItems: 2,
  totalItems: 7,
};
