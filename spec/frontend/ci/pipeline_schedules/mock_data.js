// Fixture located at spec/frontend/fixtures/pipeline_schedules.rb
import mockGetSinglePipelineScheduleGraphQLResponse from 'test_fixtures/graphql/pipeline_schedules/get_pipeline_schedules.query.graphql.single.json';
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

export const mockPipelineSchedulesResponseWithPagination = {
  data: {
    currentUser: mockGetPipelineSchedulesGraphQLResponse.data.currentUser,
    project: {
      id: mockGetPipelineSchedulesGraphQLResponse.data.project.id,
      projectPlanLimits: {
        ciPipelineSchedules: 100,
        __typename: 'ProjectPlanLimits',
      },
      pipelineSchedules: {
        count: 3,
        nodes: mockGetPipelineSchedulesGraphQLResponse.data.project.pipelineSchedules.nodes,
        pageInfo: {
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'eyJpZCI6IjQ0In0',
          endCursor: 'eyJpZCI6IjI4In0',
          __typename: 'PageInfo',
        },
      },
    },
  },
};

export const mockPipelineSchedulesResponsePlanLimitReached = {
  data: {
    currentUser: mockGetPipelineSchedulesGraphQLResponse.data.currentUser,
    project: {
      id: mockGetPipelineSchedulesGraphQLResponse.data.project.id,
      projectPlanLimits: {
        ciPipelineSchedules: 2,
        __typename: 'ProjectPlanLimits',
      },
      pipelineSchedules: {
        count: 3,
        nodes: mockGetPipelineSchedulesGraphQLResponse.data.project.pipelineSchedules.nodes,
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: 'eyJpZCI6IjQ0In0',
          endCursor: 'eyJpZCI6IjI4In0',
          __typename: 'PageInfo',
        },
      },
    },
  },
};

export const mockPipelineSchedulesResponseUnlimited = {
  data: {
    currentUser: mockGetPipelineSchedulesGraphQLResponse.data.currentUser,
    project: {
      id: mockGetPipelineSchedulesGraphQLResponse.data.project.id,
      projectPlanLimits: {
        ciPipelineSchedules: 0,
        __typename: 'ProjectPlanLimits',
      },
      pipelineSchedules: {
        count: 3,
        nodes: mockGetPipelineSchedulesGraphQLResponse.data.project.pipelineSchedules.nodes,
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: 'eyJpZCI6IjQ0In0',
          endCursor: 'eyJpZCI6IjI4In0',
          __typename: 'PageInfo',
        },
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
      projectPlanLimits: {
        ciPipelineSchedules: 100,
        __typename: 'ProjectPlanLimits',
      },
      pipelineSchedules: {
        count: 0,
        nodes: [],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: '',
          endCursor: '',
          __typename: 'PageInfo',
        },
      },
    },
  },
};

export const noPlanLimitResponse = {
  data: {
    currentUser: mockGetPipelineSchedulesGraphQLResponse.data.currentUser,
    project: {
      id: mockGetPipelineSchedulesGraphQLResponse.data.project.id,
      projectPlanLimits: {
        ciPipelineSchedules: null,
        __typename: 'ProjectPlanLimits',
      },
      pipelineSchedules: {
        count: 3,
        nodes: mockGetPipelineSchedulesGraphQLResponse.data.project.pipelineSchedules.nodes,
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: 'eyJpZCI6IjQ0In0',
          endCursor: 'eyJpZCI6IjI4In0',
          __typename: 'PageInfo',
        },
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
