// Fixture located at spec/frontend/fixtures/pipeline_schedules.rb
import mockGetPipelineSchedulesGraphQLResponse from 'test_fixtures/graphql/pipeline_schedules/get_pipeline_schedules.query.graphql.json';
import mockGetPipelineSchedulesAsGuestGraphQLResponse from 'test_fixtures/graphql/pipeline_schedules/get_pipeline_schedules.query.graphql.as_guest.json';
import mockGetPipelineSchedulesTakeOwnershipGraphQLResponse from 'test_fixtures/graphql/pipeline_schedules/get_pipeline_schedules.query.graphql.take_ownership.json';
import mockGetSinglePipelineScheduleGraphQLResponse from 'test_fixtures/graphql/pipeline_schedules/get_pipeline_schedules.query.graphql.single.json';

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
export const mockSinglePipelineScheduleNode = mockGetSinglePipelineScheduleGraphQLResponse;

export const mockSinglePipelineScheduleNodeNoVars = {
  data: {
    currentUser: mockGetPipelineSchedulesGraphQLResponse.data.currentUser,
    project: {
      id: mockGetPipelineSchedulesGraphQLResponse.data.project.id,
      pipelineSchedules: {
        count: 1,
        nodes: [mockGetPipelineSchedulesGraphQLResponse.data.project.pipelineSchedules.nodes[1]],
      },
    },
  },
};

export const emptyPipelineSchedulesResponse = {
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      username: 'root',
    },
    project: {
      id: 'gid://gitlab/Project/1',
      pipelineSchedules: {
        count: 0,
        nodes: [],
      },
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

export const createScheduleMutationResponse = {
  data: {
    pipelineScheduleCreate: {
      clientMutationId: null,
      errors: [],
      __typename: 'PipelineScheduleCreatePayload',
    },
  },
};

export const updateScheduleMutationResponse = {
  data: {
    pipelineScheduleUpdate: {
      clientMutationId: null,
      errors: [],
      __typename: 'PipelineScheduleUpdatePayload',
    },
  },
};

export { mockGetPipelineSchedulesGraphQLResponse };
