export const mockGraphQlIssueLinks = [
  {
    issue: {
      id: 'gid://gitlab/Issue/647',
      title: 'Minus corrupti provident autem nisi veritatis dicta.',
      state: 'opened',
      description: 'Illum harum laborum ipsum repellendus unde maxime eaque.',
      confidential: false,
      createdAt: '2024-05-25T22:49:16Z',
      closedAt: null,
      webUrl: 'http://127.0.0.1:3000/gitlab-org/gitlab-shell/-/issues/45',
      dueDate: '2024-08-30',
      reference: '#45',
      weight: 2,
      assignees: {
        nodes: [
          {
            id: 'gid://gitlab/User/1',
            avatarUrl:
              'https://www.gravatar.com/avatar/6ff3626da4f065bf63f9fa28289f327903d1aefca2308ef28e02dfc7ca298b11?s=80&d=identicon',
            name: 'Administrator',
            username: 'root',
            webUrl: 'http://127.0.0.1:3000/root',
            webPath: '/root',
          },
        ],
      },
      milestone: {
        expired: false,
        id: 'gid://gitlab/Milestone/13',
        title: 'v2.0',
        state: 'active',
        startDate: '2024-08-31',
        dueDate: '2024-09-30',
      },
    },
  },
];

export const createRelatedIssuesQueryMockResult = (linksName) => ({
  data: {
    project: {
      id: 'gid://gitlab/Project/3',
      [linksName]: {
        nodes: [...mockGraphQlIssueLinks],
      },
    },
  },
});

export const mockRelatedIssues = [
  {
    id: 647,
    title: 'Minus corrupti provident autem nisi veritatis dicta.',
    state: 'opened',
    description: 'Illum harum laborum ipsum repellendus unde maxime eaque.',
    confidential: false,
    createdAt: '2024-05-25T22:49:16Z',
    closedAt: null,
    webUrl: 'http://127.0.0.1:3000/gitlab-org/gitlab-shell/-/issues/45',
    dueDate: '2024-08-30',
    reference: '#45',
    weight: 2,
    assignees: [
      {
        id: 1,
        avatarUrl:
          'https://www.gravatar.com/avatar/6ff3626da4f065bf63f9fa28289f327903d1aefca2308ef28e02dfc7ca298b11?s=80&d=identicon',
        name: 'Administrator',
        username: 'root',
        webUrl: 'http://127.0.0.1:3000/root',
        webPath: '/root',
      },
    ],
    milestone: {
      expired: false,
      id: 13,
      title: 'v2.0',
      state: 'active',
      startDate: '2024-08-31',
      dueDate: '2024-09-30',
    },
    path: 'http://127.0.0.1:3000/gitlab-org/gitlab-shell/-/issues/45',
    type: 'issue',
  },
];
