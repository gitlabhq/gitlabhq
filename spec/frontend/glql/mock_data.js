export const MOCK_ISSUE = {
  webUrl: 'https://gitlab.com/gitlab-org/gitlab-test/-/issues/1',
  title: 'Issue 1',
};

export const MOCK_USER = {
  webUrl: 'https://gitlab.com/foobar',
  username: 'foobar',
};

export const MOCK_MILESTONE = {
  webPath: '/gitlab-org/gitlab-test/-/milestones/1',
  title: 'Milestone 1',
};

export const MOCK_ISSUES = {
  nodes: [
    {
      title: 'Issue 1',
      author: { username: 'foobar', webUrl: 'https://gitlab.com/foobar' },
      webUrl: 'https://gitlab.com/gitlab-org/gitlab-test/-/issues/1',
      state: 'opened',
    },
    {
      title: 'Issue 2',
      author: { username: 'janedoe', webUrl: 'https://gitlab.com/janedoe' },
      webUrl: 'https://gitlab.com/gitlab-org/gitlab-test/-/issues/2',
      state: 'closed',
    },
  ],
};

export const MOCK_FIELDS = ['title', 'author', 'state'];
