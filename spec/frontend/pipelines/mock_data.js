const PIPELINE_RUNNING = 'RUNNING';
const PIPELINE_CANCELED = 'CANCELED';
const PIPELINE_FAILED = 'FAILED';

const threeWeeksAgo = new Date();
threeWeeksAgo.setDate(threeWeeksAgo.getDate() - 21);

export const mockPipelineHeader = {
  detailedStatus: {},
  id: 123,
  userPermissions: {
    destroyPipeline: true,
    updatePipeline: true,
  },
  createdAt: threeWeeksAgo.toISOString(),
  user: {
    id: 'user-1',
    name: 'Foo',
    username: 'foobar',
    email: 'foo@bar.com',
    avatarUrl: 'link',
  },
};

export const mockFailedPipelineHeader = {
  ...mockPipelineHeader,
  status: PIPELINE_FAILED,
  retryable: true,
  cancelable: false,
  detailedStatus: {
    id: 'status-1',
    group: 'failed',
    icon: 'status_failed',
    label: 'failed',
    text: 'failed',
    detailsPath: 'path',
  },
};

export const mockFailedPipelineNoPermissions = {
  id: 123,
  userPermissions: {
    destroyPipeline: false,
    updatePipeline: false,
  },
  createdAt: threeWeeksAgo.toISOString(),
  user: {
    id: 'user-1',
    name: 'Foo',
    username: 'foobar',
    email: 'foo@bar.com',
    avatarUrl: 'link',
  },
  status: PIPELINE_RUNNING,
  retryable: true,
  cancelable: false,
  detailedStatus: {
    id: 'status-1',
    group: 'running',
    icon: 'status_running',
    label: 'running',
    text: 'running',
    detailsPath: 'path',
  },
};

export const mockRunningPipelineHeader = {
  ...mockPipelineHeader,
  status: PIPELINE_RUNNING,
  retryable: false,
  cancelable: true,
  detailedStatus: {
    id: 'status-1',
    group: 'running',
    icon: 'status_running',
    label: 'running',
    text: 'running',
    detailsPath: 'path',
  },
};

export const mockRunningPipelineNoPermissions = {
  id: 123,
  userPermissions: {
    destroyPipeline: false,
    updatePipeline: false,
  },
  createdAt: threeWeeksAgo.toISOString(),
  user: {
    id: 'user-1',
    name: 'Foo',
    username: 'foobar',
    email: 'foo@bar.com',
    avatarUrl: 'link',
  },
  status: PIPELINE_RUNNING,
  retryable: false,
  cancelable: true,
  detailedStatus: {
    id: 'status-1',
    group: 'running',
    icon: 'status_running',
    label: 'running',
    text: 'running',
    detailsPath: 'path',
  },
};

export const mockCancelledPipelineHeader = {
  ...mockPipelineHeader,
  status: PIPELINE_CANCELED,
  retryable: true,
  cancelable: false,
  detailedStatus: {
    id: 'status-1',
    group: 'cancelled',
    icon: 'status_cancelled',
    label: 'cancelled',
    text: 'cancelled',
    detailsPath: 'path',
  },
};

export const mockSuccessfulPipelineHeader = {
  ...mockPipelineHeader,
  status: 'SUCCESS',
  retryable: false,
  cancelable: false,
  detailedStatus: {
    id: 'status-1',
    group: 'success',
    icon: 'status_success',
    label: 'success',
    text: 'success',
    detailsPath: 'path',
  },
};

export const mockRunningPipelineHeaderData = {
  data: {
    project: {
      id: '1',
      pipeline: {
        ...mockRunningPipelineHeader,
        iid: '28',
        user: {
          id: 'user-1',
          name: 'Foo',
          username: 'foobar',
          webPath: '/foo',
          webUrl: '/foo',
          email: 'foo@bar.com',
          avatarUrl: 'link',
          status: null,
          __typename: 'UserCore',
        },
        __typename: 'Pipeline',
      },
      __typename: 'Project',
    },
  },
};

export const stageReply = {
  name: 'deploy',
  title: 'deploy: running',
  latest_statuses: [
    {
      id: 928,
      name: 'stop staging',
      started: false,
      build_path: '/twitter/flight/-/jobs/928',
      cancel_path: '/twitter/flight/-/jobs/928/cancel',
      playable: false,
      created_at: '2018-04-04T20:02:02.728Z',
      updated_at: '2018-04-04T20:02:02.766Z',
      status: {
        icon: 'status_pending',
        text: 'pending',
        label: 'pending',
        group: 'pending',
        tooltip: 'pending',
        has_details: true,
        details_path: '/twitter/flight/-/jobs/928',
        favicon:
          '/assets/ci_favicons/dev/favicon_status_pending-db32e1faf94b9f89530ac519790920d1f18ea8f6af6cd2e0a26cd6840cacf101.ico',
        action: {
          icon: 'cancel',
          title: 'Cancel',
          path: '/twitter/flight/-/jobs/928/cancel',
          method: 'post',
        },
      },
    },
    {
      id: 926,
      name: 'production',
      started: false,
      build_path: '/twitter/flight/-/jobs/926',
      retry_path: '/twitter/flight/-/jobs/926/retry',
      play_path: '/twitter/flight/-/jobs/926/play',
      playable: true,
      created_at: '2018-04-04T20:00:57.202Z',
      updated_at: '2018-04-04T20:11:13.110Z',
      status: {
        icon: 'status_canceled',
        text: 'canceled',
        label: 'manual play action',
        group: 'canceled',
        tooltip: 'canceled',
        has_details: true,
        details_path: '/twitter/flight/-/jobs/926',
        favicon:
          '/assets/ci_favicons/dev/favicon_status_canceled-5491840b9b6feafba0bc599cbd49ee9580321dc809683856cf1b0d51532b1af6.ico',
        action: {
          icon: 'play',
          title: 'Play',
          path: '/twitter/flight/-/jobs/926/play',
          method: 'post',
        },
      },
    },
    {
      id: 217,
      name: 'staging',
      started: '2018-03-07T08:41:46.234Z',
      build_path: '/twitter/flight/-/jobs/217',
      retry_path: '/twitter/flight/-/jobs/217/retry',
      playable: false,
      created_at: '2018-03-07T14:41:58.093Z',
      updated_at: '2018-03-07T14:41:58.093Z',
      status: {
        icon: 'status_success',
        text: 'passed',
        label: 'passed',
        group: 'success',
        tooltip: 'passed',
        has_details: true,
        details_path: '/twitter/flight/-/jobs/217',
        favicon:
          '/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico',
        action: {
          icon: 'retry',
          title: 'Retry',
          path: '/twitter/flight/-/jobs/217/retry',
          method: 'post',
        },
      },
    },
  ],
  status: {
    icon: 'status_running',
    text: 'running',
    label: 'running',
    group: 'running',
    tooltip: 'running',
    has_details: true,
    details_path: '/twitter/flight/pipelines/13#deploy',
    favicon:
      '/assets/ci_favicons/dev/favicon_status_running-c3ad2fc53ea6079c174e5b6c1351ff349e99ec3af5a5622fb77b0fe53ea279c1.ico',
  },
  path: '/twitter/flight/pipelines/13#deploy',
  dropdown_path: '/twitter/flight/pipelines/13/stage.json?stage=deploy',
};

export const users = [
  {
    id: 1,
    name: 'Administrator',
    username: 'root',
    state: 'active',
    avatar_url:
      'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
    web_url: 'http://192.168.1.22:3000/root',
  },
  {
    id: 10,
    name: 'Angel Spinka',
    username: 'shalonda',
    state: 'active',
    avatar_url:
      'https://www.gravatar.com/avatar/709df1b65ad06764ee2b0edf1b49fc27?s=80\u0026d=identicon',
    web_url: 'http://192.168.1.22:3000/shalonda',
  },
  {
    id: 11,
    name: 'Art Davis',
    username: 'deja.green',
    state: 'active',
    avatar_url:
      'https://www.gravatar.com/avatar/bb56834c061522760e7a6dd7d431a306?s=80\u0026d=identicon',
    web_url: 'http://192.168.1.22:3000/deja.green',
  },
  {
    id: 32,
    name: 'Arnold Mante',
    username: 'reported_user_10',
    state: 'active',
    avatar_url:
      'https://www.gravatar.com/avatar/ab558033a82466d7905179e837d7723a?s=80\u0026d=identicon',
    web_url: 'http://192.168.1.22:3000/reported_user_10',
  },
  {
    id: 38,
    name: 'Cher Wintheiser',
    username: 'reported_user_16',
    state: 'active',
    avatar_url:
      'https://www.gravatar.com/avatar/2640356e8b5bc4314133090994ed162b?s=80\u0026d=identicon',
    web_url: 'http://192.168.1.22:3000/reported_user_16',
  },
  {
    id: 39,
    name: 'Bethel Wolf',
    username: 'reported_user_17',
    state: 'active',
    avatar_url:
      'https://www.gravatar.com/avatar/4b948694fadba4b01e4acfc06b065e8e?s=80\u0026d=identicon',
    web_url: 'http://192.168.1.22:3000/reported_user_17',
  },
];

export const branches = [
  {
    name: 'branch-1',
    commit: {
      id: '21fb056cc47dcf706670e6de635b1b326490ebdc',
      short_id: '21fb056c',
      created_at: '2020-05-07T10:58:28.000-04:00',
      parent_ids: null,
      title: 'Add new file',
      message: 'Add new file',
      author_name: 'Administrator',
      author_email: 'admin@example.com',
      authored_date: '2020-05-07T10:58:28.000-04:00',
      committer_name: 'Administrator',
      committer_email: 'admin@example.com',
      committed_date: '2020-05-07T10:58:28.000-04:00',
      web_url:
        'http://192.168.1.22:3000/root/dag-pipeline/-/commit/21fb056cc47dcf706670e6de635b1b326490ebdc',
    },
    merged: false,
    protected: false,
    developers_can_push: false,
    developers_can_merge: false,
    can_push: true,
    default: false,
    web_url: 'http://192.168.1.22:3000/root/dag-pipeline/-/tree/branch-1',
  },
  {
    name: 'branch-10',
    commit: {
      id: '66673b07efef254dab7d537f0433a40e61cf84fe',
      short_id: '66673b07',
      created_at: '2020-03-16T11:04:46.000-04:00',
      parent_ids: null,
      title: 'Update .gitlab-ci.yml',
      message: 'Update .gitlab-ci.yml',
      author_name: 'Administrator',
      author_email: 'admin@example.com',
      authored_date: '2020-03-16T11:04:46.000-04:00',
      committer_name: 'Administrator',
      committer_email: 'admin@example.com',
      committed_date: '2020-03-16T11:04:46.000-04:00',
      web_url:
        'http://192.168.1.22:3000/root/dag-pipeline/-/commit/66673b07efef254dab7d537f0433a40e61cf84fe',
    },
    merged: false,
    protected: false,
    developers_can_push: false,
    developers_can_merge: false,
    can_push: true,
    default: false,
    web_url: 'http://192.168.1.22:3000/root/dag-pipeline/-/tree/branch-10',
  },
  {
    name: 'branch-11',
    commit: {
      id: '66673b07efef254dab7d537f0433a40e61cf84fe',
      short_id: '66673b07',
      created_at: '2020-03-16T11:04:46.000-04:00',
      parent_ids: null,
      title: 'Update .gitlab-ci.yml',
      message: 'Update .gitlab-ci.yml',
      author_name: 'Administrator',
      author_email: 'admin@example.com',
      authored_date: '2020-03-16T11:04:46.000-04:00',
      committer_name: 'Administrator',
      committer_email: 'admin@example.com',
      committed_date: '2020-03-16T11:04:46.000-04:00',
      web_url:
        'http://192.168.1.22:3000/root/dag-pipeline/-/commit/66673b07efef254dab7d537f0433a40e61cf84fe',
    },
    merged: false,
    protected: false,
    developers_can_push: false,
    developers_can_merge: false,
    can_push: true,
    default: false,
    web_url: 'http://192.168.1.22:3000/root/dag-pipeline/-/tree/branch-11',
  },
];

export const tags = [
  {
    name: 'tag-3',
    message: '',
    target: '66673b07efef254dab7d537f0433a40e61cf84fe',
    commit: {
      id: '66673b07efef254dab7d537f0433a40e61cf84fe',
      short_id: '66673b07',
      created_at: '2020-03-16T11:04:46.000-04:00',
      parent_ids: ['def28bf679235071140180495f25b657e2203587'],
      title: 'Update .gitlab-ci.yml',
      message: 'Update .gitlab-ci.yml',
      author_name: 'Administrator',
      author_email: 'admin@example.com',
      authored_date: '2020-03-16T11:04:46.000-04:00',
      committer_name: 'Administrator',
      committer_email: 'admin@example.com',
      committed_date: '2020-03-16T11:04:46.000-04:00',
      web_url:
        'http://192.168.1.22:3000/root/dag-pipeline/-/commit/66673b07efef254dab7d537f0433a40e61cf84fe',
    },
    release: null,
    protected: false,
  },
  {
    name: 'tag-2',
    message: '',
    target: '66673b07efef254dab7d537f0433a40e61cf84fe',
    commit: {
      id: '66673b07efef254dab7d537f0433a40e61cf84fe',
      short_id: '66673b07',
      created_at: '2020-03-16T11:04:46.000-04:00',
      parent_ids: ['def28bf679235071140180495f25b657e2203587'],
      title: 'Update .gitlab-ci.yml',
      message: 'Update .gitlab-ci.yml',
      author_name: 'Administrator',
      author_email: 'admin@example.com',
      authored_date: '2020-03-16T11:04:46.000-04:00',
      committer_name: 'Administrator',
      committer_email: 'admin@example.com',
      committed_date: '2020-03-16T11:04:46.000-04:00',
      web_url:
        'http://192.168.1.22:3000/root/dag-pipeline/-/commit/66673b07efef254dab7d537f0433a40e61cf84fe',
    },
    release: null,
    protected: false,
  },
  {
    name: 'tag-1',
    message: '',
    target: '66673b07efef254dab7d537f0433a40e61cf84fe',
    commit: {
      id: '66673b07efef254dab7d537f0433a40e61cf84fe',
      short_id: '66673b07',
      created_at: '2020-03-16T11:04:46.000-04:00',
      parent_ids: ['def28bf679235071140180495f25b657e2203587'],
      title: 'Update .gitlab-ci.yml',
      message: 'Update .gitlab-ci.yml',
      author_name: 'Administrator',
      author_email: 'admin@example.com',
      authored_date: '2020-03-16T11:04:46.000-04:00',
      committer_name: 'Administrator',
      committer_email: 'admin@example.com',
      committed_date: '2020-03-16T11:04:46.000-04:00',
      web_url:
        'http://192.168.1.22:3000/root/dag-pipeline/-/commit/66673b07efef254dab7d537f0433a40e61cf84fe',
    },
    release: null,
    protected: false,
  },
  {
    name: 'main-tag',
    message: '',
    target: '66673b07efef254dab7d537f0433a40e61cf84fe',
    commit: {
      id: '66673b07efef254dab7d537f0433a40e61cf84fe',
      short_id: '66673b07',
      created_at: '2020-03-16T11:04:46.000-04:00',
      parent_ids: ['def28bf679235071140180495f25b657e2203587'],
      title: 'Update .gitlab-ci.yml',
      message: 'Update .gitlab-ci.yml',
      author_name: 'Administrator',
      author_email: 'admin@example.com',
      authored_date: '2020-03-16T11:04:46.000-04:00',
      committer_name: 'Administrator',
      committer_email: 'admin@example.com',
      committed_date: '2020-03-16T11:04:46.000-04:00',
      web_url:
        'http://192.168.1.22:3000/root/dag-pipeline/-/commit/66673b07efef254dab7d537f0433a40e61cf84fe',
    },
    release: null,
    protected: false,
  },
];

export const mockSearch = [
  { type: 'username', value: { data: 'root', operator: '=' } },
  { type: 'ref', value: { data: 'main', operator: '=' } },
  { type: 'status', value: { data: 'pending', operator: '=' } },
];

export const mockBranchesAfterMap = ['branch-1', 'branch-10', 'branch-11'];

export const mockTagsAfterMap = ['tag-3', 'tag-2', 'tag-1', 'main-tag'];

export const mockPipelineJobsQueryResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/20',
      __typename: 'Project',
      pipeline: {
        id: 'gid://gitlab/Ci::Pipeline/224',
        __typename: 'Pipeline',
        jobs: {
          __typename: 'CiJobConnection',
          pageInfo: {
            endCursor: 'eyJpZCI6Ijg0NyJ9',
            hasNextPage: true,
            hasPreviousPage: false,
            startCursor: 'eyJpZCI6IjYyMCJ9',
            __typename: 'PageInfo',
          },
          nodes: [
            {
              artifacts: {
                nodes: [
                  {
                    downloadPath: '/root/ci-project/-/jobs/620/artifacts/download?file_type=trace',
                    fileType: 'TRACE',
                    __typename: 'CiJobArtifact',
                  },
                ],
                __typename: 'CiJobArtifactConnection',
              },
              allowFailure: false,
              status: 'SUCCESS',
              scheduledAt: null,
              manualJob: false,
              triggered: null,
              createdByTag: false,
              detailedStatus: {
                id: 'success-620-620',
                detailsPath: '/root/ci-project/-/jobs/620',
                group: 'success',
                icon: 'status_success',
                label: 'passed',
                text: 'passed',
                tooltip: 'passed (retried)',
                action: null,
                __typename: 'DetailedStatus',
              },
              id: 'gid://gitlab/Ci::Build/620',
              refName: 'main',
              refPath: '/root/ci-project/-/commits/main',
              tags: [],
              shortSha: '5acce24b',
              commitPath: '/root/ci-project/-/commit/5acce24b3737d4f0d649ad0a26ae1903a2b35f5e',
              stage: { id: 'gid://gitlab/Ci::Stage/148', name: 'test', __typename: 'CiStage' },
              name: 'coverage_job',
              duration: 4,
              finishedAt: '2021-12-06T14:13:49Z',
              coverage: 82.71,
              retryable: false,
              playable: false,
              cancelable: false,
              active: false,
              stuck: false,
              userPermissions: {
                readBuild: true,
                readJobArtifacts: true,
                updateBuild: true,
                __typename: 'JobPermissions',
              },
              __typename: 'CiJob',
            },
            {
              artifacts: {
                nodes: [
                  {
                    downloadPath: '/root/ci-project/-/jobs/619/artifacts/download?file_type=trace',
                    fileType: 'TRACE',
                    __typename: 'CiJobArtifact',
                  },
                ],
                __typename: 'CiJobArtifactConnection',
              },
              allowFailure: false,
              status: 'SUCCESS',
              scheduledAt: null,
              manualJob: false,
              triggered: null,
              createdByTag: false,
              detailedStatus: {
                id: 'success-619-619',
                detailsPath: '/root/ci-project/-/jobs/619',
                group: 'success',
                icon: 'status_success',
                label: 'passed',
                text: 'passed',
                tooltip: 'passed (retried)',
                action: null,
                __typename: 'DetailedStatus',
              },
              id: 'gid://gitlab/Ci::Build/619',
              refName: 'main',
              refPath: '/root/ci-project/-/commits/main',
              tags: [],
              shortSha: '5acce24b',
              commitPath: '/root/ci-project/-/commit/5acce24b3737d4f0d649ad0a26ae1903a2b35f5e',
              stage: { id: 'gid://gitlab/Ci::Stage/148', name: 'test', __typename: 'CiStage' },
              name: 'test_job_two',
              duration: 4,
              finishedAt: '2021-12-06T14:13:44Z',
              coverage: null,
              retryable: false,
              playable: false,
              cancelable: false,
              active: false,
              stuck: false,
              userPermissions: {
                readBuild: true,
                readJobArtifacts: true,
                updateBuild: true,
                __typename: 'JobPermissions',
              },
              __typename: 'CiJob',
            },
          ],
        },
      },
    },
  },
};

export const mockPipeline = (projectPath) => {
  return {
    pipeline: {
      id: 1,
      user: {
        id: 1,
        name: 'Administrator',
        username: 'root',
        state: 'active',
        avatar_url: '',
        web_url: 'http://0.0.0.0:3000/root',
        show_status: false,
        path: '/root',
      },
      active: false,
      source: 'merge_request_event',
      created_at: '2021-10-19T21:17:38.698Z',
      updated_at: '2021-10-21T18:00:42.758Z',
      path: 'foo',
      flags: {},
      merge_request: {
        iid: 1,
        path: `/${projectPath}/1`,
        title: 'commit',
        source_branch: 'test-commit-name',
        source_branch_path: `/${projectPath}`,
        target_branch: 'main',
        target_branch_path: `/${projectPath}/-/commit/main`,
      },
      ref: {
        name: 'refs/merge-requests/1/head',
        path: `/${projectPath}/-/commits/refs/merge-requests/1/head`,
        tag: false,
        branch: false,
        merge_request: true,
      },
      commit: {
        id: 'fd6df5b3229e213c97d308844a6f3e7fd71e8f8c',
        short_id: 'fd6df5b3',
        created_at: '2021-10-19T21:17:12.000+00:00',
        parent_ids: ['7147906b84306e83cb3fec6582a25390b75713c6'],
        title: 'Commit',
        message: 'Commit',
        author_name: 'Administrator',
        author_email: 'admin@example.com',
        authored_date: '2021-10-19T21:17:12.000+00:00',
        committer_name: 'Administrator',
        committer_email: 'admin@example.com',
        committed_date: '2021-10-19T21:17:12.000+00:00',
        trailers: {},
        web_url: '',
        author: {
          id: 1,
          name: 'Administrator',
          username: 'root',
          state: 'active',
          avatar_url: '',
          web_url: '',
          show_status: false,
          path: '/root',
        },
        author_gravatar_url: '',
        commit_url: `/${projectPath}/fd6df5b3229e213c97d308844a6f3e7fd71e8f8c`,
        commit_path: `/${projectPath}/commit/fd6df5b3229e213c97d308844a6f3e7fd71e8f8c`,
      },
      project: {
        full_path: `/${projectPath}`,
      },
      triggered_by: null,
      triggered: [],
    },
    pipelineScheduleUrl: 'foo',
    pipelineKey: 'id',
    viewType: 'root',
  };
};
