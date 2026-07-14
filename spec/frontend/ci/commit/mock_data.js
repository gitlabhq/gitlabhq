import getCommitPipelinesResponse from 'test_fixtures/graphql/pipelines/get_commit_pipelines.query.graphql.json';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_PIPELINE } from '~/graphql_shared/constants';

const projectData = getCommitPipelinesResponse.data.project;
const firstPipeline = projectData.pipelines.nodes[0];

const generateCommitPipelinesResponse = ({
  pipelines = projectData.pipelines.nodes,
  pageInfo,
} = {}) => ({
  data: {
    project: {
      ...projectData,
      pipelines: {
        ...projectData.pipelines,
        count: pipelines.length,
        nodes: pipelines,
        pageInfo: { ...projectData.pipelines.pageInfo, ...pageInfo },
      },
    },
  },
});

export const projectId = projectData.id;
export const projectFullPath = firstPipeline.project.fullPath;
export const commitSha = firstPipeline.commit.sha;

export const defaultCommitPipelinesResponse = generateCommitPipelinesResponse();
export const paginatedCommitPipelinesResponse = generateCommitPipelinesResponse({
  pageInfo: {
    hasNextPage: true,
    hasPreviousPage: false,
    endCursor: 'END_CURSOR',
  },
});
export const emptyCommitPipelinesResponse = generateCommitPipelinesResponse({
  pipelines: [],
});

const makePipeline = ({ id, status = firstPipeline.detailedStatus.name } = {}) => ({
  ...firstPipeline,
  id: convertToGraphQLId(TYPENAME_CI_PIPELINE, id),
  iid: String(id),
  detailedStatus: {
    ...firstPipeline.detailedStatus,
    id: `status-${id}`,
    name: status,
  },
});

export const generateStatusesSubscriptionEvent = ({
  id,
  status = firstPipeline.detailedStatus.name,
} = {}) => ({
  data: {
    ciPipelineStatusesUpdated: makePipeline({ id, status }),
  },
});

export const cancelPipelineResponse = {
  data: { pipelineCancel: { __typename: 'PipelineCancelPayload', errors: [] } },
};

export const retryPipelineResponse = {
  data: { pipelineRetry: { __typename: 'PipelineRetryPayload', errors: [] } },
};

export const retryPipelineResponseWithErrors = {
  data: { pipelineRetry: { __typename: 'PipelineRetryPayload', errors: ['Something went wrong'] } },
};
