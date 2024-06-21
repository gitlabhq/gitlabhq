export const mockPlaceholderUsers = [
  {
    avatar_url:
      'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
    name: 'Administrator',
    username: '@root',
    source_hostname: 'https://gitlab.com',
    source_username: '@old_root',
    status: 'pending_assignment',
  },
];

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
