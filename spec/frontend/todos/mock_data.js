export const MR_REVIEW_REQUEST_TODO = {
  id: 'gid://gitlab/Todo/29',
  state: 'pending',
  snoozedUntil: null,
  createdAt: '2024-08-02T20:17:18Z',
  action: 'review_requested',
  targetType: 'MERGEREQUEST',
  targetUrl: 'http://gdk.test:3000/gitlab-org/gitlab-test/-/merge_requests/8',
  memberAccessType: 'mergerequest',
  author: {
    id: 'gid://gitlab/User/1',
    name: 'Administrator',
    webUrl: 'http://gdk.test:3000/root',
    avatarUrl: '/uploads/-/system/user/avatar/1/avatar.png',
    __typename: 'UserCore',
  },
  note: null,
  group: null,
  project: {
    id: 'gid://gitlab/Project/2',
    nameWithNamespace: 'Gitlab Org / Gitlab Test',
    __typename: 'Project',
  },
  targetEntity: {
    mergeRequestState: 'opened',
    name: 'Can be automatically merged',
    reference: '!8',
    webPath: '/gitlab-org/gitlab-test/-/merge_requests/8',
    __typename: 'MergeRequest',
  },
  __typename: 'Todo',
};

export const MR_BUILD_FAILED_TODO = {
  id: 'gid://gitlab/Todo/28',
  state: 'pending',
  snoozedUntil: null,
  createdAt: '2024-07-23T16:18:54Z',
  action: 'build_failed',
  targetType: 'MERGEREQUEST',
  targetUrl: 'http://gdk.test:3000/flightjs/Flight/-/merge_requests/17/pipelines',
  memberAccessType: 'mergerequest',
  author: {
    id: 'gid://gitlab/User/1',
    name: 'Administrator',
    webUrl: 'http://gdk.test:3000/root',
    avatarUrl: '/uploads/-/system/user/avatar/1/avatar.png',
    __typename: 'UserCore',
  },
  note: null,
  group: null,
  project: {
    id: 'gid://gitlab/Project/7',
    nameWithNamespace: 'Flightjs / Flight',
    __typename: 'Project',
  },
  targetEntity: {
    mergeRequestState: 'opened',
    name: 'Update file .gitlab-ci.yml',
    reference: '!17',
    webPath: '/flightjs/Flight/-/merge_requests/17',
    __typename: 'MergeRequest',
  },
  __typename: 'Todo',
};

export const DESIGN_TODO = {
  id: 'gid://gitlab/Todo/435',
  state: 'pending',
  snoozedUntil: null,
  createdAt: '2024-12-06T11:33:29Z',
  action: 'directly_addressed',
  targetType: 'DESIGN',
  targetUrl:
    'http://gdk.test:3000/flightjs/Flight/-/issues/35/designs/Screenshot_2024-11-22_at_16.11.25.png#note_1760',
  memberAccessType: 'designmanagement::design',
  author: {
    id: 'gid://gitlab/User/1',
    name: 'Administrator',
    webUrl: 'http://gdk.test:3000/root',
    avatarUrl: '/uploads/-/system/user/avatar/1/avatar.png',
    __typename: 'UserCore',
  },
  note: {
    id: 'gid://gitlab/DiffNote/1760',
    bodyFirstLineHtml:
      '<p><a href="/root" data-reference-type="user" data-user="1" class="gfm gfm-project_member js-user-link current-user" title="Administrator">@root</a> What is this?</p>',
    __typename: 'Note',
  },
  group: null,
  project: {
    id: 'gid://gitlab/Project/7',
    nameWithNamespace: 'Flightjs / Flight',
    __typename: 'Project',
  },
  targetEntity: {
    name: 'Screenshot_2024-11-22_at_16.11.25.png',
    issue: {
      id: 'gid://gitlab/Issue/35',
      reference: '#35',
      name: 'Important issue',
    },
    __typename: 'Design',
  },
  __typename: 'Todo',
};

export const SAML_HIDDEN_TODO = {
  ...MR_REVIEW_REQUEST_TODO,
  targetEntity: null,
  project: null,
  group: null,
  note: null,
};

export const todosResponse = {
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      todos: {
        nodes: [MR_REVIEW_REQUEST_TODO, MR_BUILD_FAILED_TODO],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor:
            'eyJjcmVhdGVkX2F0IjoiMjAyNC0wOC0wMiAyMDoxNzoxOC41NDEwODkwMDAgKzAwMDAiLCJpZCI6IjI5In0',
          endCursor:
            'eyJjcmVhdGVkX2F0IjoiMjAyNC0wMi0yMCAyMjozMjowMS41OTIxNjMwMDAgKzAwMDAiLCJpZCI6IjIwIn0',
          __typename: 'PageInfo',
        },
        __typename: 'TodoConnection',
      },
      __typename: 'CurrentUser',
    },
  },
};

export const getPendingTodosCountResponse = {
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      todos: {
        count: 9,
        __typename: 'TodoConnection',
      },
      __typename: 'CurrentUser',
    },
  },
};

export const todosGroupsResponse = {
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      __typename: 'User',
      groups: {
        nodes: [
          {
            id: 'gid://gitlab/Group/1',
            name: 'My very first group',
            fullName: 'GitLab.org / Foo Stage / My very first group',
          },
          {
            id: 'gid://gitlab/Group/2',
            name: 'A new group',
            fullName: 'GitLab.com / Foo Stage / A new group',
          },
          {
            id: 'gid://gitlab/Group/3',
            name: "Third group's the charm",
            fullName: "GitLab.org / Bar Stage / Third group's the charm",
          },
        ],
      },
    },
  },
};

export const todosProjectsResponse = {
  data: {
    projects: {
      nodes: [
        {
          id: 'gid://gitlab/Project/1',
          name: 'My very first project',
          fullPath: 'gitlab-org/foo-stage/my-very-first-group/my-very-first-project',
        },
        {
          id: 'gid://gitlab/Project/2',
          name: 'A new project',
          fullPath: 'gitlab-com/foo-stage/a-new-project',
        },
        {
          id: 'gid://gitlab/Project/3',
          name: "Third project's the charm",
          fullPath: 'gitlab-org/bar-stage/third-projects-the-charm',
        },
      ],
    },
  },
};

export const todosAuthorsResponse = [
  {
    id: 1,
    username: 'root',
    name: 'Administrator',
    state: 'active',
    snoozedUntil: null,
    locked: false,
    avatar_url: 'http://gdk.test:3000/uploads/-/system/user/avatar/1/avatar.png',
    web_url: 'http://gdk.test:3000/root',
    status_tooltip_html: null,
    show_status: true,
    availability: 'busy',
    path: '/root',
  },
  {
    id: 16,
    username: 'delorse',
    name: 'Flo Reinger',
    state: 'active',
    snoozedUntil: null,
    locked: false,
    avatar_url:
      'https://www.gravatar.com/avatar/727bd7fe0418141812bccde70233599d64c05540e9f036134d0dde53a43b6930?s=80\u0026d=identicon',
    web_url: 'http://gdk.test:3000/delorse',
    status_tooltip_html: null,
    show_status: false,
    availability: null,
    path: '/delorse',
  },
];

export const todosMarkAllAsDoneResponse = {
  data: {
    markAllAsDone: {
      todos: todosResponse.data.currentUser.todos.nodes,
      errors: [],
    },
  },
};

export const todosMarkAllAsDoneErrorResponse = {
  data: {
    markAllAsDone: {
      todos: null,
      errors: ['Boom'],
    },
  },
};

export const todosUndoMarkAllAsDoneResponse = {
  data: {
    undoMarkAllAsDone: {
      todos: todosResponse.data.currentUser.todos.nodes,
      errors: [],
    },
  },
};

export const todosUndoMarkAllAsDoneErrorResponse = {
  data: {
    undoMarkAllAsDone: {
      todos: null,
      errors: ['Boom'],
    },
  },
};
