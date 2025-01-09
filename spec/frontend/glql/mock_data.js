export const MOCK_ISSUE = {
  __typename: 'Issue',
  webUrl: 'https://gitlab.com/gitlab-org/gitlab-test/-/issues/1',
  title: 'Issue 1',
  state: 'opened',
  reference: '#1',
};

export const MOCK_EPIC = {
  __typename: 'Epic',
  webUrl: 'https://gitlab.com/groups/gitlab-org/-/epics/1',
  title: 'Epic 1',
  state: 'opened',
  reference: '&1',
};

export const MOCK_MERGE_REQUEST = {
  __typename: 'MergeRequest',
  webUrl: 'https://gitlab.com/gitlab-org/gitlab-test/-/merge_requests/1',
  title: 'Merge request 1',
  state: 'opened',
  reference: '!1',
};

export const MOCK_USER = {
  __typename: 'UserCore',
  id: 'gid://gitlab/User/1',
  iid: '1',
  webUrl: 'https://gitlab.com/foobar',
  username: 'foobar',
  name: 'Foo Bar',
};

export const MOCK_MILESTONE = {
  __typename: 'Milestone',
  webPath: '/gitlab-org/gitlab-test/-/milestones/1',
  title: 'Milestone 1',
};

export const MOCK_ITERATION = {
  __typename: 'Iteration',
};

export const MOCK_ISSUES = {
  nodes: [
    {
      __typename: 'Issue',
      iid: '1',
      title: 'Issue 1',
      reference: '#1',
      author: { __typename: 'UserCore', username: 'foobar', webUrl: 'https://gitlab.com/foobar' },
      webUrl: 'https://gitlab.com/gitlab-org/gitlab-test/-/issues/1',
      state: 'opened',
      description: 'This is a description',
    },
    {
      __typename: 'Issue',
      iid: '2',
      title: 'Issue 2',
      reference: '#2',
      author: { __typename: 'UserCore', username: 'janedoe', webUrl: 'https://gitlab.com/janedoe' },
      webUrl: 'https://gitlab.com/gitlab-org/gitlab-test/-/issues/2',
      state: 'closed',
      description: 'This is another description',
    },
  ],
};

export const MOCK_LABELS = {
  nodes: [
    {
      __typename: 'Label',
      title: 'Label 1',
      color: '#FFAABB',
    },
    {
      __typename: 'Label',
      title: 'Label 2',
      color: '#FFBBAA',
    },
  ],
};

export const MOCK_ASSIGNEES = {
  nodes: [
    {
      __typename: 'UserCore',
      id: 'gid://gitlab/User/1',
      username: 'foobar',
      webUrl: 'https://gitlab.com/foobar',
    },
    {
      __typename: 'UserCore',
      id: 'gid://gitlab/User/2',
      username: 'janedoe',
      webUrl: 'https://gitlab.com/janedoe',
    },
  ],
};

export const MOCK_MR_AUTHOR = {
  ...MOCK_USER,
  __typename: 'MergeRequestAuthor',
};

export const MOCK_MR_ASSIGNEES = {
  nodes: MOCK_ASSIGNEES.nodes.map(({ __typename, ...assignee }) => ({
    __typename: 'MergeRequestAssignee',
    ...assignee,
  })),
};

export const MOCK_MR_REVIEWERS = {
  nodes: MOCK_ASSIGNEES.nodes.map(({ __typename, ...assignee }) => ({
    __typename: 'MergeRequestReviewer',
    ...assignee,
  })),
};

export const MOCK_FIELDS = [
  { key: 'title', label: 'Title', name: 'title' },
  { key: 'author', label: 'Author', name: 'author' },
  { key: 'state', label: 'State', name: 'state' },
  { key: 'description', label: 'Description', name: 'description' },
];
