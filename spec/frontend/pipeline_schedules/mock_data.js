// Fixture located at spec/frontend/fixtures/pipeline_schedules.rb
import mockGetPipelineSchedulesGraphQLResponse from 'test_fixtures/graphql/pipeline_schedules/get_pipeline_schedules.query.graphql.json';
import mockGetPipelineSchedulesAsGuestGraphQLResponse from 'test_fixtures/graphql/pipeline_schedules/get_pipeline_schedules.query.graphql.as_guest.json';

const {
  data: {
    project: {
      pipelineSchedules: { nodes },
    },
  },
} = mockGetPipelineSchedulesGraphQLResponse;

const {
  data: {
    project: {
      pipelineSchedules: { nodes: guestNodes },
    },
  },
} = mockGetPipelineSchedulesAsGuestGraphQLResponse;

export const mockPipelineScheduleNodes = nodes;

export const mockPipelineScheduleAsGuestNodes = guestNodes;

export const deleteMutationResponse = {
  data: {
    pipelineScheduleDelete: {
      clientMutationId: null,
      errors: [],
      __typename: 'PipelineScheduleDeletePayload',
    },
  },
};

export { mockGetPipelineSchedulesGraphQLResponse };
