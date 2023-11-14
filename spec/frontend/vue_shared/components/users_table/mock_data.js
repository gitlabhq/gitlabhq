export const MOCK_USERS = [
  {
    id: 2177,
    name: 'Nikki',
    createdAt: '2020-11-13T12:26:54.177Z',
    email: 'nikki@example.com',
    username: 'nikki',
    lastActivityOn: '2020-12-09',
    avatarUrl:
      'https://secure.gravatar.com/avatar/054f062d8b1a42b123f17e13a173cda8?s=80\\u0026d=identicon',
    badges: [
      { text: 'Admin', variant: 'success' },
      { text: "It's you!", variant: 'muted' },
    ],
    projectsCount: 0,
    actions: [],
    note: 'Create per issue #999',
  },
];

export const MOCK_ADMIN_USER_PATH = 'admin/users/:id';

export const MOCK_GROUP_COUNTS = { 2177: 5 };
