const createUser = (id) => {
  return {
    id: `gid://gitlab/User/${id}`,
    username: `test_user_${id}`,
    avatarUrl: `/path/test_user_${id}`,
    name: `Test User ${id}`,
    publicEmail: `test_user_${id}@gitlab.com`,
    createdAt: Date.now(),
    lastActivityOn: Date.now(),
  };
};

export const MOCK_ORGANIZATION_GID = 'gid://gitlab/Organizations::Organization/1';

export const MOCK_PATHS = {
  adminUser: '/admin/users/:id',
};

export const MOCK_USERS = [
  {
    badges: [],
    id: 'gid://gitlab/Organizations::OrganizationUser/3',
    user: createUser(3),
  },
  {
    badges: [],
    id: 'gid://gitlab/Organizations::OrganizationUser/2',
    user: createUser(2),
  },
  {
    badges: [
      { text: 'Admin', variant: 'success' },
      { text: "It's you!", variant: 'muted' },
    ],
    id: 'gid://gitlab/Organizations::OrganizationUser/1',
    user: createUser(1),
  },
];

export const MOCK_USERS_FORMATTED = MOCK_USERS.map(({ badges, user }) => {
  return { ...user, badges, email: user.publicEmail };
});

export const MOCK_PAGE_INFO = {
  startCursor: 'aaaa',
  endCursor: 'bbbb',
  hasNextPage: true,
  hasPreviousPage: true,
  __typename: 'PageInfo',
};
