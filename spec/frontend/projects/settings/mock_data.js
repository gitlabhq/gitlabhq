export const accessLevelsMockResponse = {
  __typename: 'PushAccessLevelConnection',
  edges: [
    {
      __typename: 'PushAccessLevelEdge',
      node: {
        __typename: 'PushAccessLevel',
        accessLevel: 40,
        accessLevelDescription: 'Key name',
        deployKey: {
          id: '14',
          title: 'Key name',
          user: {
            name: 'Jenny Smith',
            __typename: 'AccessLevelUser',
          },
          __typename: 'AccessLevelDeployKey',
        },
      },
    },
    {
      __typename: 'PushAccessLevelEdge',
      node: {
        __typename: 'PushAccessLevel',
        accessLevel: 40,
        accessLevelDescription: 'Maintainers',
      },
    },
  ],
};

export const accessLevelsMockResult = {
  total: 2,
  roles: [40],
  deployKeys: [
    {
      __typename: 'AccessLevelDeployKey',
      id: '14',
      title: 'Key name',
      user: {
        name: 'Jenny Smith',
        __typename: 'AccessLevelUser',
      },
    },
  ],
};
