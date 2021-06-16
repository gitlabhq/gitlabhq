import { TEST_HOST } from 'spec/test_constants';

export const projectData = {
  id: 1,
  name: 'abcproject',
  web_url: '',
  avatar_url: '',
  path: '',
  name_with_namespace: 'namespace/abcproject',
  branches: {
    main: {
      treeId: 'abcproject/main',
      can_push: true,
      commit: {
        id: '123',
      },
    },
  },
  mergeRequests: {},
  merge_requests_enabled: true,
  userPermissions: {},
  default_branch: 'main',
};

export const pipelines = [
  {
    id: 1,
    ref: 'main',
    sha: '123',
    details: {
      status: {
        icon: 'status_failed',
        group: 'failed',
        text: 'Failed',
      },
    },
    commit: { id: '123' },
  },
  {
    id: 2,
    ref: 'main',
    sha: '213',
    details: {
      status: {
        icon: 'status_failed',
        group: 'failed',
        text: 'Failed',
      },
    },
    commit: { id: '213' },
  },
];

export const stages = [
  {
    dropdown_path: `${TEST_HOST}/testing`,
    name: 'build',
    status: {
      icon: 'status_failed',
      group: 'failed',
      text: 'failed',
    },
  },
  {
    dropdown_path: 'testing',
    name: 'test',
    status: {
      icon: 'status_failed',
      group: 'failed',
      text: 'failed',
    },
  },
];

export const jobs = [
  {
    id: 1,
    name: 'test',
    path: 'testing',
    status: {
      icon: 'status_success',
      text: 'passed',
    },
    stage: 'test',
    duration: 1,
    started: new Date(),
  },
  {
    id: 2,
    name: 'test 2',
    path: 'testing2',
    status: {
      icon: 'status_success',
      text: 'passed',
    },
    stage: 'test',
    duration: 1,
    started: new Date(),
  },
  {
    id: 3,
    name: 'test 3',
    path: 'testing3',
    status: {
      icon: 'status_success',
      text: 'passed',
    },
    stage: 'test',
    duration: 1,
    started: new Date(),
  },
  {
    id: 4,
    name: 'test 4',
    // bridge jobs don't have details page and so there is no path attribute
    // see https://gitlab.com/gitlab-org/gitlab/-/issues/216480
    status: {
      icon: 'status_failed',
      text: 'failed',
    },
    stage: 'build',
    duration: 1,
    started: new Date(),
  },
];

export const fullPipelinesResponse = {
  data: {
    count: {
      all: 2,
    },
    pipelines: [
      {
        id: '51',
        path: 'test',
        commit: {
          id: '123',
        },
        details: {
          status: {
            icon: 'status_failed',
            text: 'failed',
          },
          stages: [...stages],
        },
      },
      {
        id: '50',
        commit: {
          id: 'abc123def456ghi789jkl',
        },
        details: {
          status: {
            icon: 'status_success',
            text: 'passed',
          },
          stages: [...stages],
        },
      },
    ],
  },
};

export const mergeRequests = [
  {
    id: 1,
    iid: 1,
    title: 'Test merge request',
    project_id: 1,
    web_url: `${TEST_HOST}/namespace/project-path/-/merge_requests/1`,
    references: {
      short: '!1',
      full: 'namespace/project-path!1',
    },
  },
];

export const branches = [
  {
    id: 1,
    name: 'main',
    commit: {
      message: 'Update main branch',
      committed_date: '2018-08-01T00:20:05Z',
    },
    can_push: true,
    protected: true,
    default: true,
  },
  {
    id: 2,
    name: 'protected/no-access',
    commit: {
      message: 'Update some stuff',
      committed_date: '2018-08-02T00:00:05Z',
    },
    can_push: false,
    protected: true,
    default: false,
  },
  {
    id: 3,
    name: 'protected/access',
    commit: {
      message: 'Update some stuff',
      committed_date: '2018-08-02T00:00:05Z',
    },
    can_push: true,
    protected: true,
    default: false,
  },
  {
    id: 4,
    name: 'regular',
    commit: {
      message: 'Update some more stuff',
      committed_date: '2018-06-30T00:20:05Z',
    },
    can_push: true,
    protected: false,
    default: false,
  },
  {
    id: 5,
    name: 'regular/no-access',
    commit: {
      message: 'Update some more stuff',
      committed_date: '2018-06-30T00:20:05Z',
    },
    can_push: false,
    protected: false,
    default: false,
  },
];
