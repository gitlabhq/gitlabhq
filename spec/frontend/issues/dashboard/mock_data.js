export const issuesQueryResponse = {
  data: {
    issues: {
      nodes: [
        {
          __persist: true,
          __typename: 'Issue',
          id: 'gid://gitlab/Issue/123456',
          iid: '789',
          closedAt: null,
          confidential: false,
          createdAt: '2021-05-22T04:08:01Z',
          downvotes: 2,
          dueDate: '2021-05-29',
          hidden: false,
          humanTimeEstimate: null,
          mergeRequestsCount: false,
          moved: false,
          reference: 'group/project#123456',
          state: 'opened',
          title: 'Issue title',
          type: 'issue',
          updatedAt: '2021-05-22T04:08:01Z',
          upvotes: 3,
          userDiscussionsCount: 4,
          webPath: 'project/-/issues/789',
          webUrl: 'project/-/issues/789',
          assignees: {
            nodes: [
              {
                __persist: true,
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
            __persist: true,
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
                __persist: true,
                id: 'gid://gitlab/ProjectLabel/456',
                color: '#333',
                title: 'Label title',
                description: 'Label description',
              },
            ],
          },
          milestone: null,
          taskCompletionStatus: {
            completedCount: 1,
            count: 2,
          },
        },
      ],
      pageInfo: {
        __typename: 'PageInfo',
        hasNextPage: true,
        hasPreviousPage: false,
        startCursor: 'startcursor',
        endCursor: 'endcursor',
      },
    },
  },
};

export const emptyIssuesQueryResponse = {
  data: {
    issues: {
      nodes: [],
      pageInfo: {
        __typename: 'PageInfo',
        hasNextPage: false,
        hasPreviousPage: false,
        startCursor: '',
        endCursor: '',
      },
    },
  },
};

export const issuesCountsQueryResponse = {
  data: {
    openedIssues: {
      count: 1,
    },
    closedIssues: {
      count: 2,
    },
    allIssues: {
      count: 3,
    },
  },
};
