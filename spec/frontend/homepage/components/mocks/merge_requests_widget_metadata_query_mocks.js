export const withItems = {
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      reviewRequestedMergeRequests: {
        count: 12,
        nodes: [
          {
            id: 'gid://gitlab/MergeRequest/1',
            updatedAt: '2025-06-12T15:13:25Z',
            __typename: 'MergeRequest',
          },
        ],
        __typename: 'MergeRequestConnection',
      },
      assignedMergeRequests: {
        count: 4,
        nodes: [
          {
            id: 'gid://gitlab/MergeRequest/2',
            updatedAt: '2025-06-10T15:13:25Z',
            __typename: 'MergeRequest',
          },
        ],
        __typename: 'MergeRequestConnection',
      },
      __typename: 'CurrentUser',
    },
  },
};

export const withoutItems = {
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      reviewRequestedMergeRequests: {
        count: 0,
        nodes: [],
        __typename: 'MergeRequestConnection',
      },
      assignedMergeRequests: {
        count: 0,
        nodes: [],
        __typename: 'MergeRequestConnection',
      },
      __typename: 'CurrentUser',
    },
  },
};
