export const mockPlaceholderUsers = [
  {
    avatar_url:
      'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
    name: 'Placeholder 1',
    username: 'placeholder-1',
    source_hostname: 'https://gitlab.com',
    source_username: '@old_root',
    status: 'pending_assignment',
  },
  {
    avatar_url:
      'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
    name: 'Placeholder 2',
    username: 'placeholder-2',
    source_hostname: 'https://gitlab.com',
    source_username: '@old_root',
    status: 'awaiting_approval',
    reassignToUser: {
      avatar_url:
        'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
      name: 'Administrator',
      username: '@root2',
    },
  },
  {
    avatar_url:
      'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
    name: 'Placeholder 3',
    username: 'placeholder-3',
    source_hostname: 'https://gitlab.com',
    source_username: '@old_root',
    status: 'rejected',
  },
  {
    avatar_url:
      'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
    name: 'Placeholder 4',
    username: 'placeholder-4',
    source_hostname: 'https://gitlab.com',
    source_username: '@old_root',
    status: 'reassignment_in_progress',
    reassignToUser: {
      avatar_url:
        'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
      name: 'Administrator',
      username: '@root4',
    },
  },
  {
    avatar_url:
      'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
    name: 'Placeholder 5',
    username: 'placeholder-5',
    source_hostname: 'https://gitlab.com',
    source_username: '@old_root',
    status: 'failed',
    reassignToUser: {
      avatar_url:
        'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
      name: 'Administrator',
      username: '@root5',
    },
  },
  {
    avatar_url:
      'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
    name: 'Placeholder 6',
    username: 'placeholder-6',
    source_hostname: 'https://gitlab.com',
    source_username: '@old_root',
    status: 'keep_as_placeholder',
    reassignToUser: {
      avatar_url:
        'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
      name: 'Administrator',
      username: '@root6',
    },
  },
  {
    avatar_url:
      'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
    name: 'Placeholder 7',
    username: 'placeholder-7',
    source_hostname: 'https://gitlab.com',
    source_username: '@old_root',
    status: 'completed',
    reassignToUser: {
      avatar_url:
        'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80&d=identicon',
      name: 'Administrator',
      username: '@root7',
    },
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
