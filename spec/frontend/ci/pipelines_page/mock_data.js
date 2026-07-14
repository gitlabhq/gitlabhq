import mockGetPipelinesResponse from 'test_fixtures/graphql/pipelines/get_pipelines.query.graphql.json';
import mockGetSinglePipelineResponse from 'test_fixtures/graphql/pipelines/get_single_pipeline.query.graphql.json';

import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_PIPELINE } from '~/graphql_shared/constants';

export { mockGetPipelinesResponse, mockGetSinglePipelineResponse };

const { pipelines, id: projectId } = mockGetPipelinesResponse.data.project;

// Pipeline ids:

// All pipeline ids in the fixture
const listPipelineNumericIds = pipelines.nodes.map((node) => getIdFromGraphQLId(node.id));

// Older pipeline: 0 is guaranteed to be older and not exist already
export const mockOlderPipelineId = convertToGraphQLId(TYPENAME_CI_PIPELINE, 0);

// Newer pipeline: max(...ids) + 1 is guaranteed to be newer than all other pipelines
export const mockNewPipelineId = convertToGraphQLId(
  TYPENAME_CI_PIPELINE,
  Math.max(...listPipelineNumericIds) + 1,
);

const responseWithFirstNode = (node) => ({
  data: {
    project: {
      ...mockGetPipelinesResponse.data.project,
      pipelines: { ...pipelines, nodes: [node] },
    },
  },
});

export const mockPipelineWithDownstream = responseWithFirstNode(
  pipelines.nodes.find((node) => node.downstream?.nodes?.length),
);

export const mockPipelineWithUpstream = responseWithFirstNode(
  pipelines.nodes.find((node) => node.upstream),
);

export const mockPipelinesDataEmpty = {
  data: {
    project: {
      id: projectId,
      pipelines: {
        nodes: [],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
          __typename: 'PageInfo',
        },
        __typename: 'PipelineConnection',
      },
      __typename: 'Project',
    },
  },
};

export const mockRunnerCacheClearPayload = {
  data: {
    runnerCacheClear: {
      errors: [],
      __typename: 'RunnerCacheClearPayload',
    },
  },
};

export const mockRunnerCacheClearPayloadWithError = {
  data: {
    runnerCacheClear: {
      errors: ['Something went wrong'],
      __typename: 'RunnerCacheClearPayload',
    },
  },
};

export const mockPipelinesCount = {
  data: {
    project: {
      id: projectId,
      pipelines: {
        count: 2,
        __typename: 'PipelineConnection',
      },
      __typename: 'Project',
    },
  },
};

export const mockRetryPipelineMutationResponse = {
  data: {
    pipelineRetry: {
      __typename: 'PipelineRetryPayload',
      errors: [],
    },
  },
};

export const mockRetryFailedPipelineMutationResponse = {
  data: {
    pipelineRetry: {
      __typename: 'PipelineRetryPayload',
      errors: ['Something went wrong'],
    },
  },
};

export const mockCancelPipelineMutationResponse = {
  data: {
    pipelineCancel: {
      __typename: 'PipelineCancelPayload',
      errors: [],
    },
  },
};

export const mockPipelinesFilteredSearch = [
  {
    type: 'username',
    value: {
      data: 'root',
      operator: '=',
    },
    id: 'token-18',
  },
  {
    type: 'status',
    value: {
      data: 'success',
      operator: '=',
    },
    id: 'token-20',
  },
  {
    type: 'source',
    value: {
      data: 'schedule',
      operator: '=',
    },
    id: 'token-22',
  },
  {
    type: 'ref',
    value: {
      data: 'test',
      operator: '=',
    },
    id: 'token-24',
  },
];

export const mockBranchPipeline = {
  __typename: 'Pipeline',
  downstream: {
    count: 1,
    __typename: 'PipelineConnection',
    nodes: [
      {
        __typename: 'Pipeline',
        id: 'gid://gitlab/Ci::Pipeline/973',
        iid: '156',
        name: null,
        path: '/root/downstream-project/-/pipelines/973',
        detailedStatus: {
          __typename: 'DetailedStatus',
          tooltip: 'passed',
          label: 'passed',
          id: 'success-973-973',
          icon: 'status_success',
          text: 'Passed',
          detailsPath: '/root/downstream-project/-/pipelines/973',
          name: 'SUCCESS',
        },
        project: {
          __typename: 'Project',
          id: 'gid://gitlab/Project/20',
          fullPath: 'root/downstream-project',
          name: 'downstream-project',
        },
        sourceJob: {
          __typename: 'CiJob',
          id: 'gid://gitlab/Ci::Bridge/2153',
          name: 'trigger_job',
          retried: false,
        },
      },
    ],
  },
  upstream: null,
  id: 'gid://gitlab/Ci::Pipeline/972',
  iid: '189',
  detailedStatus: {
    __typename: 'DetailedStatus',
    name: 'SUCCESS_WITH_WARNINGS',
    id: 'success-972-972',
    icon: 'status_warning',
    text: 'Warning',
    detailsPath: '/root/ci-project/-/pipelines/972',
  },
  finishedAt: '2026-02-06T15:44:00Z',
  duration: 68,
  name: 'Ruby 3.0 master branch pipeline',
  ref: 'main',
  refPath: 'refs/heads/main',
  commit: {
    __typename: 'Commit',
    id: 'gid://gitlab/Commit/de80f1042526e0374ba1cfdca7c1d6595406e949',
    sha: 'de80f1042526e0374ba1cfdca7c1d6595406e949',
    shortId: 'de80f104',
    title: 'Edit .gitlab-ci.yml',
    webPath: '/root/ci-project/-/commit/de80f1042526e0374ba1cfdca7c1d6595406e949',
    author: {
      __typename: 'UserCore',
      id: 'gid://gitlab/User/1',
      avatarUrl:
        'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80&d=identicon',
      webPath: '/root',
      name: 'Administrator',
    },
  },
  user: {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/1',
    name: 'Administrator',
    webPath: '/root',
    avatarUrl:
      'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80&d=identicon',
  },
  source: 'web',
  latest: true,
  yamlErrors: false,
  yamlErrorMessages: null,
  failureReason: null,
  configSource: 'REPOSITORY_SOURCE',
  stuck: false,
  type: 'branch',
  path: '/root/ci-project/-/pipelines/972',
  retryable: true,
  cancelable: false,
  stages: {
    __typename: 'CiStageConnection',
    nodes: [
      {
        __typename: 'CiStage',
        id: 'gid://gitlab/Ci::Stage/1104',
        name: 'build',
        detailedStatus: {
          __typename: 'DetailedStatus',
          tooltip: 'passed',
          id: 'success-1104-1104',
          icon: 'status_success',
          text: 'Passed',
          detailsPath: '/root/ci-project/-/pipelines/972#build',
          name: 'SUCCESS',
        },
      },
      {
        __typename: 'CiStage',
        id: 'gid://gitlab/Ci::Stage/1105',
        name: 'test',
        detailedStatus: {
          __typename: 'DetailedStatus',
          tooltip: 'passed with warnings',
          id: 'success-1105-1105',
          icon: 'status_warning',
          text: 'Warning',
          detailsPath: '/root/ci-project/-/pipelines/972#test',
          name: 'SUCCESS_WITH_WARNINGS',
        },
      },
      {
        __typename: 'CiStage',
        id: 'gid://gitlab/Ci::Stage/1106',
        name: 'deploy',
        detailedStatus: {
          __typename: 'DetailedStatus',
          tooltip: 'passed',
          id: 'success-1106-1106',
          icon: 'status_success',
          text: 'Passed',
          detailsPath: '/root/ci-project/-/pipelines/972#deploy',
          name: 'SUCCESS',
        },
      },
    ],
  },
  mergeRequest: null,
  mergeRequestEventType: null,
  project: { __typename: 'Project', id: 'gid://gitlab/Project/19', fullPath: 'root/ci-project' },
  hasManualActions: true,
  hasScheduledActions: false,
  pipelineSchedule: null,
  failedJobsCount: 1,
};
