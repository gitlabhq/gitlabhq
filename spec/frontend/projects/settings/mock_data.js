const accessLevelsMockResponse = [
  {
    __typename: 'PushAccessLevelEdge',
    node: {
      __typename: 'PushAccessLevel',
      accessLevel: 40,
      accessLevelDescription: 'Jona Langworth',
      group: null,
      user: {
        __typename: 'UserCore',
        id: '123',
        webUrl: 'test.com',
        name: 'peter',
        avatarUrl: 'test.com/user.png',
      },
    },
  },
  {
    __typename: 'PushAccessLevelEdge',
    node: {
      __typename: 'PushAccessLevel',
      accessLevel: 40,
      accessLevelDescription: 'Maintainers',
      group: null,
      user: null,
    },
  },
];

export const pushAccessLevelsMockResponse = {
  __typename: 'PushAccessLevelConnection',
  edges: accessLevelsMockResponse,
};

export const pushAccessLevelsMockResult = {
  total: 2,
  users: [
    {
      src: 'test.com/user.png',
      __typename: 'UserCore',
      id: '123',
      webUrl: 'test.com',
      name: 'peter',
      avatarUrl: 'test.com/user.png',
    },
  ],
  groups: [],
  roles: [
    {
      accessLevelDescription: 'Maintainers',
    },
  ],
};
