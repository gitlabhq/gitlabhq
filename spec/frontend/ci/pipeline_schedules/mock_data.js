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

export const mockScheduleUpdateResponse = {
  data: {
    ciPipelineScheduleStatusUpdated: {
      id: 'gid://gitlab/Ci::PipelineSchedule/4',
      lastPipeline: {
        id: 'gid://gitlab/Ci::Pipeline/631',
        detailedStatus: {
          id: 'success-631-631',
          group: 'success',
          icon: 'status_success',
          label: 'passed',
          text: 'Passed',
          detailsPath: '/root/long-running-pipeline/-/pipelines/631',
          __typename: 'DetailedStatus',
        },
        __typename: 'Pipeline',
      },
      __typename: 'PipelineSchedule',
    },
  },
};

// does not use fixture to get a consistent ID
// for testing utility function
export const mockSchedules = [
  {
    __typename: 'PipelineSchedule',
    id: 'gid://gitlab/Ci::PipelineSchedule/3',
    description: 'Schedule Two',
    cron: '20 16 1 * *',
    cronTimezone: 'America/New_York',
    ref: 'main',
    forTag: false,
    editPath: '/root/ci-project/-/pipeline_schedules/3/edit',
    refPath: '/root/ci-project/-/commits/main',
    refForDisplay: 'main',
    lastPipeline: {
      __typename: 'Pipeline',
      id: 'gid://gitlab/Ci::Pipeline/617',
      detailedStatus: {
        __typename: 'DetailedStatus',
        id: 'success-617-617',
        group: 'success-with-warnings',
        icon: 'status_warning',
        label: 'passed with warnings',
        text: 'Warning',
        detailsPath: '/root/ci-project/-/pipelines/617',
      },
    },
    active: true,
    nextRunAt: '2025-09-01T21:19:00Z',
    realNextRun: '2025-09-01T21:19:00Z',
    owner: {
      __typename: 'UserCore',
      id: 'gid://gitlab/User/1',
      username: 'root',
      avatarUrl:
        'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80&d=identicon',
      name: 'Administrator',
      webPath: '/root',
    },
    inputs: {
      __typename: 'CiInputsFieldConnection',
      nodes: [],
    },
    variables: {
      __typename: 'PipelineScheduleVariableConnection',
      nodes: [],
    },
    userPermissions: {
      __typename: 'PipelineSchedulePermissions',
      playPipelineSchedule: true,
      updatePipelineSchedule: true,
      adminPipelineSchedule: true,
    },
  },
  {
    __typename: 'PipelineSchedule',
    id: 'gid://gitlab/Ci::PipelineSchedule/4',
    description: 'Schedule One',
    cron: '51 17 * * 0',
    cronTimezone: 'America/New_York',
    ref: 'main',
    forTag: false,
    editPath: '/root/long-running-pipeline/-/pipeline_schedules/4/edit',
    refPath: '/root/long-running-pipeline/-/commits/main',
    refForDisplay: 'main',
    lastPipeline: {
      __typename: 'Pipeline',
      id: 'gid://gitlab/Ci::Pipeline/631',
      detailedStatus: {
        __typename: 'DetailedStatus',
        id: 'running-631-631',
        group: 'running',
        icon: 'status_running',
        label: 'running',
        text: 'Running',
        detailsPath: '/root/long-running-pipeline/-/pipelines/631',
      },
    },
    active: true,
    nextRunAt: '2025-08-24T22:19:00Z',
    realNextRun: '2025-08-24T22:19:00Z',
    owner: {
      __typename: 'UserCore',
      id: 'gid://gitlab/User/1',
      username: 'root',
      avatarUrl:
        'https://www.gravatar.com/avatar/3699a2727a92a410332ca568fef4353e3ae40c0b0c1fd5043585ceec77dc0e05?s=80&d=identicon',
      name: 'Administrator',
      webPath: '/root',
    },
    inputs: { __typename: 'CiInputsFieldConnection', nodes: [] },
    variables: { __typename: 'PipelineScheduleVariableConnection', nodes: [] },
    userPermissions: {
      __typename: 'PipelineSchedulePermissions',
      playPipelineSchedule: true,
      updatePipelineSchedule: true,
      adminPipelineSchedule: true,
    },
  },
];

export { mockGetPipelineSchedulesGraphQLResponse };
