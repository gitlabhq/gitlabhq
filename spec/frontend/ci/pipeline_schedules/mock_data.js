// Fixture located at spec/frontend/fixtures/pipeline_schedules.rb
import mockGetPipelineSchedulesGraphQLResponse from 'test_fixtures/graphql/pipeline_schedules/get_pipeline_schedules.query.graphql.json';
import mockGetPipelineSchedulesAsGuestGraphQLResponse from 'test_fixtures/graphql/pipeline_schedules/get_pipeline_schedules.query.graphql.as_guest.json';
import mockGetPipelineSchedulesTakeOwnershipGraphQLResponse from 'test_fixtures/graphql/pipeline_schedules/get_pipeline_schedules.query.graphql.take_ownership.json';

const {
  data: {
    currentUser,
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

const {
  data: {
    project: {
      pipelineSchedules: { nodes: takeOwnershipNodes },
    },
  },
} = mockGetPipelineSchedulesTakeOwnershipGraphQLResponse;

export const mockPipelineScheduleNodes = nodes;
export const mockPipelineScheduleCurrentUser = currentUser;

export const mockPipelineScheduleAsGuestNodes = guestNodes;

export const mockTakeOwnershipNodes = takeOwnershipNodes;
export const emptyPipelineSchedulesResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      pipelineSchedules: { nodes: [], count: 0 },
    },
  },
};

export const deleteMutationResponse = {
  data: {
    pipelineScheduleDelete: {
      clientMutationId: null,
      errors: [],
      __typename: 'PipelineScheduleDeletePayload',
    },
  },
};

export const playMutationResponse = {
  data: {
    pipelineSchedulePlay: {
      clientMutationId: null,
      errors: [],
      __typename: 'PipelineSchedulePlayPayload',
    },
  },
};

export const takeOwnershipMutationResponse = {
  data: {
    pipelineScheduleTakeOwnership: {
      pipelineSchedule: {
        id: '1',
        owner: {
          id: '2',
          name: 'Admin',
        },
      },
      errors: [],
      __typename: 'PipelineScheduleTakeOwnershipPayload',
    },
  },
};

export { mockGetPipelineSchedulesGraphQLResponse };
