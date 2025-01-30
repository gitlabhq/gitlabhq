export const triggers = [
  {
    id: 1,
    hasTokenExposed: true,
    token: '0000',
    description: 'My trigger',
    owner: {
      name: 'My User',
      username: 'user1',
      path: '/user1',
    },
    lastUsed: null,
    expiresAt: null,
    canAccessProject: true,
    projectTriggerPath: '/trigger/1',
  },
  {
    id: 2,
    hasTokenExposed: false,
    token: '1111',
    description: "Another user's trigger",
    owner: {
      name: 'Someone else',
      username: 'user2',
      path: '/user2',
    },
    lastUsed: '2020-09-10T08:26:47.410Z',
    expiresAt: '2024-04-10T08:26:47.410Z',
    canAccessProject: false,
    projectTriggerPath: '/trigger/2',
  },
];

export const mockPipelineTriggerMutationResponse = ({
  errors = [],
  description = 'My trigger',
} = {}) => ({
  data: {
    pipelineTriggerUpdate: {
      pipelineTrigger: {
        id: 'gid://gitlab/Ci::Trigger/1',
        description,
      },
      errors,
    },
  },
});
