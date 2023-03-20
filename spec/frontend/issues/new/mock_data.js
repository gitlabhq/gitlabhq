import { TEST_HOST } from 'helpers/test_constants';

function getDate(daysMinus) {
  const today = new Date();
  today.setDate(today.getDate() - daysMinus);

  return today.toISOString();
}

export default () => ({
  id: 1,
  iid: 1,
  state: 'opened',
  upvotes: 1,
  userNotesCount: 2,
  closedAt: getDate(1),
  createdAt: getDate(3),
  updatedAt: getDate(2),
  confidential: false,
  webUrl: `${TEST_HOST}/test/issue/1`,
  title: 'Test issue',
  author: {
    avatarUrl: `${TEST_HOST}/avatar`,
    name: 'Author Name',
    username: 'author.username',
    webUrl: `${TEST_HOST}/author`,
  },
});

export const mockIssueSuggestionResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/278964',
      issues: {
        edges: [
          {
            node: {
              id: 'gid://gitlab/Issue/123725957',
              iid: '696',
              title: 'Remove unused MR widget extension expand success, failed, warning events',
              confidential: false,
              userNotesCount: 16,
              upvotes: 0,
              webUrl: 'https://gitlab.com/gitlab-org/gitlab/-/issues/696',
              state: 'opened',
              closedAt: null,
              createdAt: '2023-02-15T12:29:59Z',
              updatedAt: '2023-03-01T19:38:22Z',
              author: {
                id: 'gid://gitlab/User/325',
                name: 'User Name',
                username: 'user-name',
                avatarUrl: '/uploads/-/system/user/avatar/325/avatar.png',
                webUrl: 'https://gitlab.com/user-name',
                __typename: 'UserCore',
              },
              __typename: 'Issue',
            },
            __typename: 'IssueEdge',
          },
          {
            node: {
              id: 'gid://gitlab/Issue/123',
              iid: '391',
              title: 'Remove unused MR widget extension expand success, failed, warning events',
              confidential: false,
              userNotesCount: 16,
              upvotes: 0,
              webUrl: 'https://gitlab.com/gitlab-org/gitlab/-/issues/391',
              state: 'opened',
              closedAt: null,
              createdAt: '2023-02-15T12:29:59Z',
              updatedAt: '2023-03-01T19:38:22Z',
              author: {
                id: 'gid://gitlab/User/2080',
                name: 'User Name',
                username: 'user-name',
                avatarUrl: '/uploads/-/system/user/avatar/2080/avatar.png',
                webUrl: 'https://gitlab.com/user-name',
                __typename: 'UserCore',
              },
              __typename: 'Issue',
            },
            __typename: 'IssueEdge',
          },
        ],
        __typename: 'IssueConnection',
      },
      __typename: 'Project',
    },
  },
};
