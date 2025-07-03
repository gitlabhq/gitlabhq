export const withItems = {
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      assigned: {
        count: 5,
        nodes: [
          {
            id: 'gid://gitlab/WorkItem/20',
            updatedAt: '2025-06-27T19:25:04Z',
            __typename: 'WorkItem',
          },
        ],
        __typename: 'WorkItemConnection',
      },
      authored: {
        count: 32,
        nodes: [
          {
            id: 'gid://gitlab/WorkItem/619',
            updatedAt: '2025-06-25T15:52:05Z',
            __typename: 'WorkItem',
          },
        ],
        __typename: 'WorkItemConnection',
      },
      __typename: 'CurrentUser',
    },
  },
};

export const withoutItems = {
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      assigned: {
        count: 0,
        nodes: [],
        __typename: 'WorkItemConnection',
      },
      authored: {
        count: 0,
        nodes: [],
        __typename: 'WorkItemConnection',
      },
      __typename: 'CurrentUser',
    },
  },
};
