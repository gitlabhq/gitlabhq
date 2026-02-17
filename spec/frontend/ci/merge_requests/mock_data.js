export const generateMockPipeline = ({
  id = '123',
  mergeRequestEventType = 'DETACHED',
  status = 'SUCCESS',
} = {}) => ({
  id: `gid://gitlab/Ci::Pipeline/${id}`,
  iid: id,
  path: `/project/pipelines/${id}`,
  duration: 1000,
  name: null,
  createdAt: '2024-01-15T10:29:00Z',
  finishedAt: '2024-01-15T10:30:00Z',
  configSource: 'REPOSITORY_SOURCE',
  mergeRequestEventType,
  stuck: false,
  failureReason: null,
  yamlErrors: false,
  yamlErrorMessages: null,
  latest: true,
  retryable: true,
  cancelable: false,
  ref: 'refs/merge-requests/1/head',
  refPath: 'refs/heads/root-main-patch-56329',
  refText: '',
  source: 'merge_request_event',
  type: 'merge_request',
  hasManualActions: true,
  hasScheduledActions: false,
  failedJobsCount: 0,
  __typename: 'Pipeline',
  commit: {
    id: 'gid://gitlab/Ci::Commit/1',
    name: "Merge branch '419724-apollo-mr-pipelines-build-pipeline-table-component-2' into 'master' ",
    title:
      "Merge branch '419724-apollo-mr-pipelines-build-pipeline-table-component-2' into 'master' ",
    webPath: '/gitlab-org/gitlab/-/commit/a43ea6d3a453f8e603fb3558024c084c45c0c9e4',
    webUrl: '/gitlab-org/gitlab/-/commit/a43ea6d3a453f8e603fb3558024c084c45c0c9e4',
    shortId: 'a43ea6d3',
    sha: 'a43ea6d3fc81257b1caeeaceb21b36349110ad54',
    authorGravatar:
      'https://secure.gravatar.com/avatar/295d89332b1f3e65933ee72a5f1a6081dc048333a42a5dd2bb8e81fd45590b30?s=80&d=identicon',
    author: {
      id: '1',
      avatarUrl: '/uploads/-/system/user/avatar/5327378/avatar.png',
      commitEmail: 'rando@gitlab.com',
      name: 'Random User',
      webUrl: 'https://gitlab.com/random_user',
      webPath: '/random_user',
      __typename: 'UserCore',
    },
    __typename: 'Commit',
  },
  detailedStatus: {
    id: `${status.toLowerCase()}-${id}-${id}`,
    hasDetails: true,
    detailsPath: `/gitlab-org/gitlab/-/pipelines/${id}`,
    label: status.toLowerCase(),
    name: status,
    icon: `status_${status.toLowerCase()}`,
    text: status,
    __typename: 'DetailedStatus',
  },
  stages: {
    nodes: [
      {
        id: 'gid://gitlab/Ci::Stage/1949',
        name: 'build',
        detailedStatus: {
          id: 'success-1949-1949',
          icon: 'status_success',
          text: 'Passed',
          detailsPath: `/gitlab-org/gitlab/-/pipelines/${id}#build`,
          tooltip: 'passed',
          __typename: 'DetailedStatus',
        },
        __typename: 'CiStage',
      },
      {
        id: 'gid://gitlab/Ci::Stage/1950',
        name: 'test',
        detailedStatus: {
          id: 'success-1950-1950',
          icon: 'status_success',
          text: 'Passed',
          detailsPath: `/gitlab-org/gitlab/-/pipelines/${id}#test`,
          tooltip: 'passed',
          __typename: 'DetailedStatus',
        },
        __typename: 'CiStage',
      },
      {
        id: 'gid://gitlab/Ci::Stage/1951',
        name: 'deploy',
        detailedStatus: {
          id: 'success-1951-1951',
          icon: 'status_success',
          text: 'Passed',
          detailsPath: `/gitlab-org/gitlab/-/pipelines/${id}#deploy`,
          tooltip: 'passed',
          __typename: 'DetailedStatus',
        },
        __typename: 'CiStage',
      },
    ],
    __typename: 'CiStageConnection',
  },
  mergeRequest: {
    id: 'gid://gitlab/MergeRequest/1',
    iid: '1',
    webPath: '/gitlab-org/gitlab/-/merge_requests/1',
    title: 'Edit README.md',
    sourceBranch: 'test-branch',
    __typename: 'MergeRequest',
  },
  project: {
    id: 'gid://gitlab/Project/1',
    fullPath: 'gitlab-org/gitlab',
    __typename: 'Project',
  },
  user: {
    id: 'gid://gitlab/User/1',
    avatarUrl: '/uploads/-/system/user/avatar/5327378/avatar.png',
    name: 'Random User',
    path: '/random_user',
    webPath: '/random_user',
    __typename: 'UserCore',
  },
});

const createMergeRequestPipelines = ({
  mergeRequestEventType = 'MERGE_TRAIN',
  count = 1,
  status = 'SKIPPED',
} = {}) => {
  const pipelines = [];

  for (let i = 1; i <= count; i += 1) {
    pipelines.push(generateMockPipeline({ id: String(i), mergeRequestEventType, status }));
  }

  return {
    count,
    nodes: pipelines,
    pageInfo: {
      hasNextPage: true,
      hasPreviousPage: false,
      startCursor: 'eyJpZCI6IjcwMSJ9',
      endCursor: 'eyJpZCI6IjY3NSJ9',
      __typename: 'PageInfo',
    },
    __typename: 'PipelineConnection',
  };
};

export const generateMRPipelinesResponse = ({
  mergeRequestEventType = '',
  count = 1,
  status = 'SKIPPED',
} = {}) => {
  return {
    data: {
      project: {
        __typename: 'Project',
        id: 'gid://gitlab/Project/1',
        fullPath: 'root/project-1',
        mergeRequest: {
          __typename: 'MergeRequest',
          id: 'gid://gitlab/MergeRequest/1',
          iid: '1',
          title: 'Fix everything',
          webPath: '/merge_requests/1',
          pipelines: createMergeRequestPipelines({ count, mergeRequestEventType, status }),
        },
      },
    },
  };
};

export const mockPipelineUpdateResponse = {
  data: {
    ciPipelineStatusUpdated: {
      id: 'gid://gitlab/Ci::Pipeline/701',
      iid: '63',
      detailedStatus: {
        id: 'running-701-701',
        icon: 'status_running',
        text: 'Running',
        detailsPath: '/root/ci-project/-/pipelines/880',
        __typename: 'DetailedStatus',
        name: 'RUNNING',
        label: 'running',
        hasDetails: true,
      },
      createdAt: '2025-12-08T20:06:34Z',
      finishedAt: null,
      duration: null,
      name: 'Ruby 3.0 master branch pipeline',
      ref: 'main',
      refPath: 'refs/heads/main',
      refText:
        'In <a class="ref-container gl-link" href="/root/ci-project/-/commits/main">main</a>',
      commit: {
        id: 'gid://gitlab/Commit/577d7917b5d80ef8cd8e543186aae41ccd870022',
        name: 'Edit .gitlab-ci.yml',
        sha: '577d7917b5d80ef8cd8e543186aae41ccd870022',
        shortId: '577d7917',
        title: 'Edit .gitlab-ci.yml',
        webUrl:
          'http://gdk.test:3000/root/ci-project/-/commit/577d7917b5d80ef8cd8e543186aae41ccd870022',
        author: {
          id: 'gid://gitlab/User/1',
          avatarUrl:
            'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80&d=identicon',
          webPath: '/root',
          name: 'Administrator',
          __typename: 'UserCore',
        },
        __typename: 'Commit',
      },
      user: {
        id: 'gid://gitlab/User/1',
        name: 'Administrator',
        webPath: '/root',
        avatarUrl:
          'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80&d=identicon',
        __typename: 'UserCore',
      },
      source: 'web',
      latest: true,
      yamlErrors: false,
      yamlErrorMessages: null,
      failureReason: null,
      configSource: 'REPOSITORY_SOURCE',
      stuck: false,
      type: 'branch',
      path: '/root/ci-project/-/pipelines/880',
      retryable: false,
      cancelable: true,
      stages: {
        nodes: [
          {
            id: 'gid://gitlab/Ci::Stage/870',
            name: 'build',
            detailedStatus: {
              id: 'running-870-870',
              icon: 'status_running',
              text: 'Running',
              detailsPath: '/root/ci-project/-/pipelines/880#build',
              __typename: 'DetailedStatus',
              tooltip: 'running',
            },
            __typename: 'CiStage',
          },
          {
            id: 'gid://gitlab/Ci::Stage/871',
            name: 'test',
            detailedStatus: {
              id: 'created-871-871',
              icon: 'status_created',
              text: 'Created',
              detailsPath: '/root/ci-project/-/pipelines/880#test',
              __typename: 'DetailedStatus',
              tooltip: 'created',
            },
            __typename: 'CiStage',
          },
          {
            id: 'gid://gitlab/Ci::Stage/872',
            name: 'deploy',
            detailedStatus: {
              id: 'created-872-872',
              icon: 'status_created',
              text: 'Created',
              detailsPath: '/root/ci-project/-/pipelines/880#deploy',
              __typename: 'DetailedStatus',
              tooltip: 'created',
            },
            __typename: 'CiStage',
          },
        ],
        __typename: 'CiStageConnection',
      },
      mergeRequest: null,
      mergeRequestEventType: null,
      project: {
        id: 'gid://gitlab/Project/19',
        fullPath: 'root/ci-project',
        __typename: 'Project',
      },
      hasManualActions: false,
      hasScheduledActions: false,
      failedJobsCount: 0,
      __typename: 'Pipeline',
      downstream: {
        nodes: [],
        __typename: 'PipelineConnection',
      },
    },
  },
};

export const mockPipelineUpdateResponseEmpty = {
  data: {
    ciPipelineStatusUpdated: null,
  },
};

export const mockPipelines = [
  {
    id: 'gid://gitlab/Ci::Pipeline/701',
    iid: '63',
    detailedStatus: {
      id: 'success-701-701',
      icon: 'status_warning',
      label: 'passed with warnings',
      text: 'Warning',
      detailsPath: '/root/ci-project/-/pipelines/701',
      hasDetails: true,
      __typename: 'DetailedStatus',
      name: 'SUCCESS_WITH_WARNINGS',
    },
    createdAt: '2025-09-25T16:23:33Z',
    finishedAt: '2025-09-25T16:24:02Z',
    duration: 17,
    failedJobsCount: 0,
    name: 'Ruby 3.0 master branch pipeline',
    ref: 'main',
    refPath: 'refs/heads/main',
    refText:
      'For \u003ca class="ref-container gl-link" href="/root/ci-project/-/commits/main"\u003emain\u003c/a\u003e',
    commit: {
      id: 'gid://gitlab/Commit/ab708cdcfd838846528c736f36ac2d2fea4508fb',
      name: 'Update .gitlab-ci.yml file',
      sha: 'ab708cdcfd838846528c736f36ac2d2fea4508fb',
      shortId: 'ab708cdc',
      title: 'Update .gitlab-ci.yml file',
      webUrl:
        'http://gdk.test:3000/root/ci-project/-/commit/ab708cdcfd838846528c736f36ac2d2fea4508fb',
      author: {
        id: 'gid://gitlab/User/1',
        avatarUrl:
          'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80\u0026d=identicon',
        webPath: '/root',
        name: 'Administrator',
        __typename: 'UserCore',
      },
      __typename: 'Commit',
    },
    user: {
      id: 'gid://gitlab/User/1',
      name: 'Administrator',
      webPath: '/root',
      avatarUrl:
        'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80\u0026d=identicon',
      __typename: 'UserCore',
    },
    source: 'schedule',
    latest: true,
    yamlErrors: false,
    yamlErrorMessages: '',
    failureReason: null,
    configSource: 'REPOSITORY_SOURCE',
    stuck: false,
    type: 'branch',
    path: '/root/ci-project/-/pipelines/701',
    retryable: true,
    cancelable: false,
    downstream: { __typename: 'PipelineConnection', nodes: [] },
    stages: {
      nodes: [
        {
          id: 'gid://gitlab/Ci::Stage/429',
          name: 'build',
          detailedStatus: {
            id: 'success-429-429',
            icon: 'status_success',
            text: 'Passed',
            detailsPath: '/root/ci-project/-/pipelines/701#build',
            __typename: 'DetailedStatus',
            tooltip: 'passed',
          },
          __typename: 'CiStage',
        },
        {
          id: 'gid://gitlab/Ci::Stage/431',
          name: 'test',
          detailedStatus: {
            id: 'success-431-431',
            icon: 'status_warning',
            text: 'Warning',
            detailsPath: '/root/ci-project/-/pipelines/701#test',
            __typename: 'DetailedStatus',
            tooltip: 'passed',
          },
          __typename: 'CiStage',
        },
        {
          id: 'gid://gitlab/Ci::Stage/434',
          name: 'deploy',
          detailedStatus: {
            id: 'success-434-434',
            icon: 'status_success',
            text: 'Passed',
            detailsPath: '/root/ci-project/-/pipelines/701#deploy',
            __typename: 'DetailedStatus',
            tooltip: 'passed',
          },
          __typename: 'CiStage',
        },
      ],
      __typename: 'CiStageConnection',
    },
    mergeRequest: null,
    mergeRequestEventType: null,
    project: {
      id: 'gid://gitlab/Project/19',
      fullPath: 'root/ci-project',
      __typename: 'Project',
    },
    hasManualActions: false,
    hasScheduledActions: false,
    __typename: 'Pipeline',
  },
  {
    id: 'gid://gitlab/Ci::Pipeline/699',
    iid: '62',
    detailedStatus: {
      id: 'success-699-699',
      icon: 'status_warning',
      label: 'passed with warnings',
      text: 'Warning',
      detailsPath: '/root/ci-project/-/pipelines/699',
      hasDetails: true,
      __typename: 'DetailedStatus',
      name: 'SUCCESS_WITH_WARNINGS',
    },
    createdAt: '2025-09-18T15:04:38Z',
    finishedAt: '2025-09-18T15:04:59Z',
    duration: 16,
    failedJobsCount: 0,
    name: 'Ruby 3.0 master branch pipeline',
    ref: 'main',
    refPath: 'refs/heads/main',
    refText:
      'For \u003ca class="ref-container gl-link" href="/root/ci-project/-/commits/main"\u003emain\u003c/a\u003e',
    commit: {
      id: 'gid://gitlab/Commit/ab708cdcfd838846528c736f36ac2d2fea4508fb',
      name: 'Update .gitlab-ci.yml file',
      sha: 'ab708cdcfd838846528c736f36ac2d2fea4508fb',
      shortId: 'ab708cdc',
      title: 'Update .gitlab-ci.yml file',
      webUrl:
        'http://gdk.test:3000/root/ci-project/-/commit/ab708cdcfd838846528c736f36ac2d2fea4508fb',
      author: {
        id: 'gid://gitlab/User/1',
        avatarUrl:
          'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80\u0026d=identicon',
        webPath: '/root',
        name: 'Administrator',
        __typename: 'UserCore',
      },
      __typename: 'Commit',
    },
    user: {
      id: 'gid://gitlab/User/1',
      name: 'Administrator',
      webPath: '/root',
      avatarUrl:
        'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80\u0026d=identicon',
      __typename: 'UserCore',
    },
    source: 'web',
    latest: true,
    yamlErrors: false,
    yamlErrorMessages: '',
    failureReason: null,
    configSource: 'REPOSITORY_SOURCE',
    stuck: false,
    type: 'branch',
    path: '/root/ci-project/-/pipelines/699',
    retryable: true,
    cancelable: false,
    downstream: { __typename: 'PipelineConnection', nodes: [] },
    stages: {
      nodes: [
        {
          id: 'gid://gitlab/Ci::Stage/424',
          name: 'build',
          detailedStatus: {
            id: 'success-424-424',
            icon: 'status_success',
            text: 'Passed',
            detailsPath: '/root/ci-project/-/pipelines/699#build',
            __typename: 'DetailedStatus',
            tooltip: 'passed',
          },
          __typename: 'CiStage',
        },
        {
          id: 'gid://gitlab/Ci::Stage/425',
          name: 'test',
          detailedStatus: {
            id: 'success-425-425',
            icon: 'status_warning',
            text: 'Warning',
            detailsPath: '/root/ci-project/-/pipelines/699#test',
            __typename: 'DetailedStatus',
            tooltip: 'passed',
          },
          __typename: 'CiStage',
        },
        {
          id: 'gid://gitlab/Ci::Stage/426',
          name: 'deploy',
          detailedStatus: {
            id: 'success-426-426',
            icon: 'status_success',
            text: 'Passed',
            detailsPath: '/root/ci-project/-/pipelines/699#deploy',
            __typename: 'DetailedStatus',
            tooltip: 'passed',
          },
          __typename: 'CiStage',
        },
      ],
      __typename: 'CiStageConnection',
    },
    mergeRequest: null,
    mergeRequestEventType: null,
    project: {
      id: 'gid://gitlab/Project/19',
      fullPath: 'root/ci-project',
      __typename: 'Project',
    },
    hasManualActions: false,
    hasScheduledActions: false,
    __typename: 'Pipeline',
  },
];
