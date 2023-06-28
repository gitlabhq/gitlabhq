export const getServiceDeskIssuesQueryResponse = {
  data: {
    project: {
      id: '1',
      __typename: 'Project',
      issues: {
        __persist: true,
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'startcursor',
          endCursor: 'endcursor',
        },
        nodes: [
          {
            __persist: true,
            __typename: 'Issue',
            id: 'gid://gitlab/Issue/123456',
            iid: '789',
            confidential: false,
            createdAt: '2021-05-22T04:08:01Z',
            downvotes: 2,
            dueDate: '2021-05-29',
            hidden: false,
            humanTimeEstimate: null,
            mergeRequestsCount: false,
            moved: false,
            state: 'opened',
            title: 'Issue title',
            updatedAt: '2021-05-22T04:08:01Z',
            closedAt: null,
            upvotes: 3,
            userDiscussionsCount: 4,
            webPath: 'project/-/issues/789',
            webUrl: 'project/-/issues/789',
            type: 'issue',
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
                },
              ],
            },
            author: {
              __persist: true,
              __typename: 'UserCore',
              id: 'gid://gitlab/User/456',
              avatarUrl: 'avatar/url',
              name: 'GitLab Support Bot',
              username: 'support-bot',
              webUrl: 'url/hsimpson',
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
      },
    },
  },
};

export const getServiceDeskIssuesQueryEmptyResponse = {
  data: {
    project: {
      id: '1',
      __typename: 'Project',
      issues: {
        __persist: true,
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'startcursor',
          endCursor: 'endcursor',
        },
        nodes: [],
      },
    },
  },
};

export const getServiceDeskIssuesCountsQueryResponse = {
  data: {
    project: {
      id: '1',
      openedIssues: {
        count: 1,
      },
      closedIssues: {
        count: 1,
      },
      allIssues: {
        count: 1,
      },
    },
  },
};
