export const getQueryResponse = {
  data: {
    project: {
      id: '1',
      __typename: 'Project',
      mergeRequests: {
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'startcursor',
          endCursor: 'endcursor',
        },
        nodes: [
          {
            __typename: 'MergeRequest',
            id: 'gid://gitlab/MergeRequest/123456',
            iid: '789',
            createdAt: '2021-05-22T04:08:01Z',
            downvotes: 2,
            state: 'opened',
            title: 'Merge request title',
            updatedAt: '2021-05-22T04:08:01Z',
            upvotes: 3,
            userDiscussionsCount: 4,
            webUrl: 'project/-/merge_requests/789',
            assignees: {
              nodes: [
                {
                  __typename: 'UserCore',
                  id: 'gid://gitlab/User/234',
                  avatarUrl: 'avatar/url',
                  name: 'Marge Simpson',
                  username: 'msimpson',
                  webUrl: 'url/msimpson',
                  webPath: '/msimpson',
                },
              ],
            },
            author: {
              __typename: 'UserCore',
              id: 'gid://gitlab/User/456',
              avatarUrl: 'avatar/url',
              name: 'Homer Simpson',
              username: 'hsimpson',
              webUrl: 'url/hsimpson',
              webPath: '/hsimpson',
            },
            labels: {
              nodes: [
                {
                  id: 'gid://gitlab/ProjectLabel/456',
                  color: '#333',
                  title: 'Label title',
                  description: 'Label description',
                },
              ],
            },
            milestone: null,
            headPipeline: null,
            commitCount: 1,
            conflicts: false,
            sourceBranchExists: true,
            targetBranchExists: true,
            approved: false,
            approvedBy: {
              nodes: [
                {
                  id: 1,
                },
              ],
            },
          },
        ],
      },
    },
  },
};

export const getCountsQueryResponse = {
  data: {
    project: {
      id: 1,
      openedMergeRequests: { count: 1 },
      mergedMergeRequests: { count: 1 },
      closedMergeRequests: { count: 1 },
      allMergeRequests: { count: 1 },
    },
  },
};
