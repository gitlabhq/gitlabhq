export const getStatesResponse = {
  data: {
    project: {
      id: 'project-1',
      terraformStates: {
        count: 1,
        nodes: {
          _showDetails: true,
          errorMessages: [],
          loadingLock: false,
          loadingRemove: false,
          id: 'state-1',
          name: 'state',
          lockedAt: '01-01-2022',
          updatedAt: '01-01-2022',
          lockedByUser: {
            id: 'user-1',
            avatarUrl: 'avatar',
            name: 'User 1',
            username: 'user-1',
            webUrl: 'web',
          },
          latestVersion: null,
        },
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'prev',
          endCursor: 'next',
        },
      },
    },
  },
};
