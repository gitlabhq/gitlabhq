export const createAgentResponse = {
  data: {
    createClusterAgent: {
      clusterAgent: {
        id: 'agent-id',
      },
      errors: [],
    },
  },
};

export const createAgentErrorResponse = {
  data: {
    createClusterAgent: {
      clusterAgent: {
        id: 'agent-id',
      },
      errors: ['could not create agent'],
    },
  },
};

export const createAgentTokenResponse = {
  data: {
    clusterAgentTokenCreate: {
      token: {
        id: 'token-id',
      },
      secret: 'mock-agent-token',
      errors: [],
    },
  },
};

export const createAgentTokenErrorResponse = {
  data: {
    clusterAgentTokenCreate: {
      token: {
        id: 'token-id',
      },
      secret: 'mock-agent-token',
      errors: ['could not create agent token'],
    },
  },
};
