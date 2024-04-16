// pipeline header fixtures located in spec/frontend/fixtures/pipeline_header.rb
import pipelineHeaderSuccess from 'test_fixtures/graphql/pipelines/pipeline_header_success.json';
import pipelineHeaderRunning from 'test_fixtures/graphql/pipelines/pipeline_header_running.json';
import pipelineHeaderRunningNoPermissions from 'test_fixtures/graphql/pipelines/pipeline_header_running_no_permissions.json';
import pipelineHeaderRunningWithDuration from 'test_fixtures/graphql/pipelines/pipeline_header_running_with_duration.json';
import pipelineHeaderFailed from 'test_fixtures/graphql/pipelines/pipeline_header_failed.json';

const PIPELINE_RUNNING = 'RUNNING';

const threeWeeksAgo = new Date();
threeWeeksAgo.setDate(threeWeeksAgo.getDate() - 21);

export {
  pipelineHeaderSuccess,
  pipelineHeaderRunning,
  pipelineHeaderRunningNoPermissions,
  pipelineHeaderRunningWithDuration,
  pipelineHeaderFailed,
};

export const pipelineHeaderTrigger = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      pipeline: {
        ...pipelineHeaderSuccess.data.project.pipeline,
        trigger: true,
      },
    },
  },
};

export const pipelineRetryMutationResponseSuccess = {
  data: { pipelineRetry: { errors: [] } },
};

export const pipelineRetryMutationResponseFailed = {
  data: { pipelineRetry: { errors: ['error'] } },
};

export const pipelineCancelMutationResponseSuccess = {
  data: { pipelineCancel: { errors: [] } },
};

export const pipelineCancelMutationResponseFailed = {
  data: { pipelineCancel: { errors: ['error'] } },
};

export const pipelineDeleteMutationResponseSuccess = {
  data: { pipelineDestroy: { errors: [] } },
};

export const pipelineDeleteMutationResponseFailed = {
  data: { pipelineDestroy: { errors: ['error'] } },
};

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

export const pipelineHeaderFailedNoPermissions = {
  data: {
    project: {
      id: '1',
      pipeline: {
        ...pipelineHeaderFailed.data.project.pipeline,
        userPermissions: {
          destroyPipeline: false,
          cancelPipeline: false,
          updatePipeline: false,
        },
      },
    },
  },
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
    pipelineSchedulesPath: 'foo',
    pipelineKey: 'id',
    viewType: 'root',
  };
};

export const mockPipelineTag = () => {
  return {
    pipeline: {
      id: 311,
      iid: 37,
      user: {
        id: 1,
        username: 'root',
        name: 'Administrator',
        state: 'active',
        avatar_url:
          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        web_url: 'http://gdk.test:3000/root',
        show_status: false,
        path: '/root',
      },
      active: false,
      source: 'push',
      name: 'Build pipeline',
      created_at: '2022-02-02T15:39:04.012Z',
      updated_at: '2022-02-02T15:40:59.573Z',
      path: '/root/mr-widgets/-/pipelines/311',
      flags: {
        stuck: false,
        auto_devops: false,
        merge_request: false,
        yaml_errors: false,
        retryable: true,
        cancelable: false,
        failure_reason: false,
        detached_merge_request_pipeline: false,
        merge_request_pipeline: false,
        merge_train_pipeline: false,
        latest: true,
      },
      details: {
        status: {
          icon: 'status_warning',
          text: 'passed',
          label: 'passed with warnings',
          group: 'success-with-warnings',
          tooltip: 'passed',
          has_details: true,
          details_path: '/root/mr-widgets/-/pipelines/311',
          illustration: null,
          favicon:
            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
        },
        stages: [
          {
            name: 'accessibility',
            title: 'accessibility: passed',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/root/mr-widgets/-/pipelines/311#accessibility',
              illustration: null,
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
            },
            path: '/root/mr-widgets/-/pipelines/311#accessibility',
            dropdown_path: '/root/mr-widgets/-/pipelines/311/stage.json?stage=accessibility',
          },
          {
            name: 'validate',
            title: 'validate: passed with warnings',
            status: {
              icon: 'status_warning',
              text: 'passed',
              label: 'passed with warnings',
              group: 'success-with-warnings',
              tooltip: 'passed',
              has_details: true,
              details_path: '/root/mr-widgets/-/pipelines/311#validate',
              illustration: null,
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
            },
            path: '/root/mr-widgets/-/pipelines/311#validate',
            dropdown_path: '/root/mr-widgets/-/pipelines/311/stage.json?stage=validate',
          },
          {
            name: 'test',
            title: 'test: passed',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/root/mr-widgets/-/pipelines/311#test',
              illustration: null,
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
            },
            path: '/root/mr-widgets/-/pipelines/311#test',
            dropdown_path: '/root/mr-widgets/-/pipelines/311/stage.json?stage=test',
          },
          {
            name: 'build',
            title: 'build: passed',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/root/mr-widgets/-/pipelines/311#build',
              illustration: null,
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
            },
            path: '/root/mr-widgets/-/pipelines/311#build',
            dropdown_path: '/root/mr-widgets/-/pipelines/311/stage.json?stage=build',
          },
        ],
        duration: 93,
        finished_at: '2022-02-02T15:40:59.384Z',
        event_type_name: 'Pipeline',
        manual_actions: [],
        scheduled_actions: [],
      },
      ref: {
        name: 'test',
        path: '/root/mr-widgets/-/commits/test',
        tag: true,
        branch: false,
        merge_request: false,
      },
      commit: {
        id: '9b92b4f730d1611bd9a086ca221ae206d5da1e59',
        short_id: '9b92b4f7',
        created_at: '2022-01-13T13:59:03.000+00:00',
        parent_ids: ['0ba763634114e207dc72c65c8e9459556b1204fb'],
        title: 'Update hello_world.js',
        message: 'Update hello_world.js',
        author_name: 'Administrator',
        author_email: 'admin@example.com',
        authored_date: '2022-01-13T13:59:03.000+00:00',
        committer_name: 'Administrator',
        committer_email: 'admin@example.com',
        committed_date: '2022-01-13T13:59:03.000+00:00',
        trailers: {},
        web_url:
          'http://gdk.test:3000/root/mr-widgets/-/commit/9b92b4f730d1611bd9a086ca221ae206d5da1e59',
        author: {
          id: 1,
          username: 'root',
          name: 'Administrator',
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          web_url: 'http://gdk.test:3000/root',
          show_status: false,
          path: '/root',
        },
        author_gravatar_url:
          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        commit_url:
          'http://gdk.test:3000/root/mr-widgets/-/commit/9b92b4f730d1611bd9a086ca221ae206d5da1e59',
        commit_path: '/root/mr-widgets/-/commit/9b92b4f730d1611bd9a086ca221ae206d5da1e59',
      },
      retry_path: '/root/mr-widgets/-/pipelines/311/retry',
      delete_path: '/root/mr-widgets/-/pipelines/311',
      failed_builds: [
        {
          id: 1696,
          name: 'fmt',
          started: '2022-02-02T15:39:45.192Z',
          complete: true,
          archived: false,
          build_path: '/root/mr-widgets/-/jobs/1696',
          retry_path: '/root/mr-widgets/-/jobs/1696/retry',
          playable: false,
          scheduled: false,
          created_at: '2022-02-02T15:39:04.136Z',
          updated_at: '2022-02-02T15:39:57.969Z',
          status: {
            icon: 'status_warning',
            text: 'failed',
            label: 'failed (allowed to fail)',
            group: 'failed-with-warnings',
            tooltip: 'failed - (script failure) (allowed to fail)',
            has_details: true,
            details_path: '/root/mr-widgets/-/jobs/1696',
            illustration: {
              image:
                '/assets/illustrations/empty-state/empty-job-skipped-md-29a8a37d8a61d1b6f68cf3484f9024e53cd6eb95e28eae3554f8011a1146bf27.svg',
              size: '',
              title: 'This job does not have a trace.',
            },
            favicon:
              '/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
            action: {
              icon: 'retry',
              title: 'Retry',
              path: '/root/mr-widgets/-/jobs/1696/retry',
              method: 'post',
              button_title: 'Retry this job',
            },
          },
          recoverable: false,
        },
      ],
      project: {
        id: 23,
        name: 'mr-widgets',
        full_path: '/root/mr-widgets',
        full_name: 'Administrator / mr-widgets',
      },
      triggered_by: null,
      triggered: [],
    },
    pipelineSchedulesPath: 'foo',
    pipelineKey: 'id',
    viewType: 'root',
  };
};

export const mockPipelineBranch = () => {
  return {
    pipeline: {
      id: 268,
      iid: 34,
      user: {
        id: 1,
        username: 'root',
        name: 'Administrator',
        state: 'active',
        avatar_url:
          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        web_url: 'http://gdk.test:3000/root',
        show_status: false,
        path: '/root',
      },
      active: false,
      source: 'push',
      name: 'Build pipeline',
      created_at: '2022-01-14T17:40:27.866Z',
      updated_at: '2022-01-14T18:02:35.850Z',
      path: '/root/mr-widgets/-/pipelines/268',
      flags: {
        stuck: false,
        auto_devops: false,
        merge_request: false,
        yaml_errors: false,
        retryable: true,
        cancelable: false,
        failure_reason: false,
        detached_merge_request_pipeline: false,
        merge_request_pipeline: false,
        merge_train_pipeline: false,
        latest: true,
      },
      details: {
        status: {
          icon: 'status_warning',
          text: 'passed',
          label: 'passed with warnings',
          group: 'success-with-warnings',
          tooltip: 'passed',
          has_details: true,
          details_path: '/root/mr-widgets/-/pipelines/268',
          illustration: null,
          favicon:
            '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
        },
        stages: [
          {
            name: 'validate',
            title: 'validate: passed with warnings',
            status: {
              icon: 'status_warning',
              text: 'passed',
              label: 'passed with warnings',
              group: 'success-with-warnings',
              tooltip: 'passed',
              has_details: true,
              details_path: '/root/mr-widgets/-/pipelines/268#validate',
              illustration: null,
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
            },
            path: '/root/mr-widgets/-/pipelines/268#validate',
            dropdown_path: '/root/mr-widgets/-/pipelines/268/stage.json?stage=validate',
          },
          {
            name: 'test',
            title: 'test: passed',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/root/mr-widgets/-/pipelines/268#test',
              illustration: null,
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
            },
            path: '/root/mr-widgets/-/pipelines/268#test',
            dropdown_path: '/root/mr-widgets/-/pipelines/268/stage.json?stage=test',
          },
          {
            name: 'build',
            title: 'build: passed',
            status: {
              icon: 'status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              tooltip: 'passed',
              has_details: true,
              details_path: '/root/mr-widgets/-/pipelines/268#build',
              illustration: null,
              favicon:
                '/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png',
            },
            path: '/root/mr-widgets/-/pipelines/268#build',
            dropdown_path: '/root/mr-widgets/-/pipelines/268/stage.json?stage=build',
          },
        ],
        duration: 75,
        finished_at: '2022-01-14T18:02:35.842Z',
        event_type_name: 'Pipeline',
        manual_actions: [],
        scheduled_actions: [],
      },
      ref: {
        name: 'update-ci',
        path: '/root/mr-widgets/-/commits/update-ci',
        tag: false,
        branch: true,
        merge_request: false,
      },
      commit: {
        id: '96aef9ecec5752c09371c1ade5fc77860aafc863',
        short_id: '96aef9ec',
        created_at: '2022-01-14T17:40:26.000+00:00',
        parent_ids: ['06860257572d4cf84b73806250b78169050aed83'],
        title: 'Update main.tf',
        message: 'Update main.tf',
        author_name: 'Administrator',
        author_email: 'admin@example.com',
        authored_date: '2022-01-14T17:40:26.000+00:00',
        committer_name: 'Administrator',
        committer_email: 'admin@example.com',
        committed_date: '2022-01-14T17:40:26.000+00:00',
        trailers: {},
        web_url:
          'http://gdk.test:3000/root/mr-widgets/-/commit/96aef9ecec5752c09371c1ade5fc77860aafc863',
        author: {
          id: 1,
          username: 'root',
          name: 'Administrator',
          state: 'active',
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          web_url: 'http://gdk.test:3000/root',
          show_status: false,
          path: '/root',
        },
        author_gravatar_url:
          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        commit_url:
          'http://gdk.test:3000/root/mr-widgets/-/commit/96aef9ecec5752c09371c1ade5fc77860aafc863',
        commit_path: '/root/mr-widgets/-/commit/96aef9ecec5752c09371c1ade5fc77860aafc863',
      },
      retry_path: '/root/mr-widgets/-/pipelines/268/retry',
      delete_path: '/root/mr-widgets/-/pipelines/268',
      failed_builds: [
        {
          id: 1260,
          name: 'fmt',
          started: '2022-01-14T17:40:36.435Z',
          complete: true,
          archived: false,
          build_path: '/root/mr-widgets/-/jobs/1260',
          retry_path: '/root/mr-widgets/-/jobs/1260/retry',
          playable: false,
          scheduled: false,
          created_at: '2022-01-14T17:40:27.879Z',
          updated_at: '2022-01-14T17:40:42.129Z',
          status: {
            icon: 'status_warning',
            text: 'failed',
            label: 'failed (allowed to fail)',
            group: 'failed-with-warnings',
            tooltip: 'failed - (script failure) (allowed to fail)',
            has_details: true,
            details_path: '/root/mr-widgets/-/jobs/1260',
            illustration: {
              image:
                '/assets/illustrations/empty-state/empty-job-skipped-md-29a8a37d8a61d1b6f68cf3484f9024e53cd6eb95e28eae3554f8011a1146bf27.svg',
              size: '',
              title: 'This job does not have a trace.',
            },
            favicon:
              '/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png',
            action: {
              icon: 'retry',
              title: 'Retry',
              path: '/root/mr-widgets/-/jobs/1260/retry',
              method: 'post',
              button_title: 'Retry this job',
            },
          },
          recoverable: false,
        },
      ],
      project: {
        id: 23,
        name: 'mr-widgets',
        full_path: '/root/mr-widgets',
        full_name: 'Administrator / mr-widgets',
      },
      triggered_by: null,
      triggered: [],
    },
    pipelineSchedulesPath: 'foo',
    pipelineKey: 'id',
    viewType: 'root',
  };
};

export const mockFailedJobsQueryResponse = {
  data: {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/20',
      pipeline: {
        __typename: 'Pipeline',
        id: 'gid://gitlab/Ci::Pipeline/300',
        jobs: {
          __typename: 'CiJobConnection',
          nodes: [
            {
              __typename: 'CiJob',
              status: 'FAILED',
              detailedStatus: {
                __typename: 'DetailedStatus',
                id: 'failed-1848-1848',
                detailsPath: '/root/ci-project/-/jobs/1848',
                group: 'failed',
                icon: 'status_failed',
                label: 'failed',
                text: 'failed',
                tooltip: 'failed - (script failure)',
                action: {
                  __typename: 'StatusAction',
                  id: 'Ci::Build-failed-1848',
                  buttonTitle: 'Retry this job',
                  icon: 'retry',
                  method: 'post',
                  path: '/root/ci-project/-/jobs/1848/retry',
                  title: 'Retry',
                },
              },
              id: 'gid://gitlab/Ci::Build/1848',
              stage: {
                __typename: 'CiStage',
                id: 'gid://gitlab/Ci::Stage/358',
                name: 'build',
              },
              name: 'wait_job',
              retryable: true,
              userPermissions: {
                __typename: 'JobPermissions',
                readBuild: true,
                updateBuild: true,
              },
              trace: {
                htmlSummary: '<span>Html Summary</span>',
              },
              failureMessage: 'Failed',
            },
            {
              __typename: 'CiJob',
              status: 'FAILED',
              detailedStatus: {
                __typename: 'DetailedStatus',
                id: 'failed-1710-1710',
                detailsPath: '/root/ci-project/-/jobs/1710',
                group: 'failed',
                icon: 'status_failed',
                label: 'failed',
                text: 'failed',
                tooltip: 'failed - (script failure) (retried)',
                action: null,
              },
              id: 'gid://gitlab/Ci::Build/1710',
              stage: {
                __typename: 'CiStage',
                id: 'gid://gitlab/Ci::Stage/358',
                name: 'build',
              },
              name: 'wait_job',
              retryable: false,
              userPermissions: {
                __typename: 'JobPermissions',
                readBuild: true,
                updateBuild: true,
              },
              trace: null,
              failureMessage: 'Failed',
            },
          ],
        },
      },
    },
  },
};

export const mockFailedJobsData = [
  {
    __typename: 'CiJob',
    status: 'FAILED',
    detailedStatus: {
      __typename: 'DetailedStatus',
      id: 'failed-1848-1848',
      detailsPath: '/root/ci-project/-/jobs/1848',
      group: 'failed',
      icon: 'status_failed',
      label: 'failed',
      text: 'failed',
      tooltip: 'failed - (script failure)',
      action: {
        __typename: 'StatusAction',
        id: 'Ci::Build-failed-1848',
        buttonTitle: 'Retry this job',
        icon: 'retry',
        method: 'post',
        path: '/root/ci-project/-/jobs/1848/retry',
        title: 'Retry',
      },
    },
    id: 'gid://gitlab/Ci::Build/1848',
    stage: {
      __typename: 'CiStage',
      id: 'gid://gitlab/Ci::Stage/358',
      name: 'build',
    },
    name: 'wait_job',
    retryable: true,
    userPermissions: {
      __typename: 'JobPermissions',
      readBuild: true,
      updateBuild: true,
    },
    trace: {
      htmlSummary: '<span>Html Summary</span>',
    },
    failureMessage: 'Job failed',
    _showDetails: true,
  },
  {
    __typename: 'CiJob',
    status: 'FAILED',
    detailedStatus: {
      __typename: 'DetailedStatus',
      id: 'failed-1710-1710',
      detailsPath: '/root/ci-project/-/jobs/1710',
      group: 'failed',
      icon: 'status_failed',
      label: 'failed',
      text: 'failed',
      tooltip: 'failed - (script failure) (retried)',
      action: null,
    },
    id: 'gid://gitlab/Ci::Build/1710',
    stage: {
      __typename: 'CiStage',
      id: 'gid://gitlab/Ci::Stage/358',
      name: 'build',
    },
    name: 'wait_job',
    retryable: false,
    userPermissions: {
      __typename: 'JobPermissions',
      readBuild: true,
      updateBuild: true,
    },
    trace: null,
    failureMessage: 'Job failed',
    _showDetails: true,
  },
];

export const mockFailedJobsDataNoPermission = [
  {
    ...mockFailedJobsData[0],
    userPermissions: { __typename: 'JobPermissions', readBuild: false, updateBuild: false },
  },
];

export const successRetryMutationResponse = {
  data: {
    jobRetry: {
      job: {
        __typename: 'CiJob',
        id: '"gid://gitlab/Ci::Build/1985"',
        detailedStatus: {
          detailsPath: '/root/project/-/jobs/1985',
          id: 'pending-1985-1985',
          __typename: 'DetailedStatus',
        },
      },
      errors: [],
      __typename: 'JobRetryPayload',
    },
  },
};

export const failedRetryMutationResponse = {
  data: {
    jobRetry: {
      job: {},
      errors: ['New Error'],
      __typename: 'JobRetryPayload',
    },
  },
};
