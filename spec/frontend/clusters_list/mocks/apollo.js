const agent = {
  __typename: 'ClusterAgent',
  id: 'agent-id',
  name: 'agent-name',
  webPath: 'agent-webPath',
  createdAt: new Date(),
};
const token = {
  id: 'token-id',
  lastUsedAt: null,
};
const tokens = {
  nodes: [token],
};
const connections = {
  nodes: [],
};

export const createAgentResponse = {
  data: {
    createClusterAgent: {
      clusterAgent: {
        ...agent,
        connections,
        tokens,
      },
      errors: [],
    },
  },
};

export const createAgentErrorResponse = {
  data: {
    createClusterAgent: {
      clusterAgent: {
        ...agent,
        connections,
        tokens,
      },
      errors: ['could not create agent'],
    },
  },
};

export const createAgentTokenResponse = {
  data: {
    clusterAgentTokenCreate: {
      token,
      secret: 'mock-agent-token',
      errors: [],
    },
  },
};

export const createAgentTokenErrorResponse = {
  data: {
    clusterAgentTokenCreate: {
      token,
      secret: 'mock-agent-token',
      errors: ['could not create agent token'],
    },
  },
};

export const getAgentResponse = {
  data: {
    project: {
      __typename: 'Project',
      id: 'project-1',
      clusterAgents: { nodes: [{ ...agent, connections, tokens }] },
      ciAccessAuthorizedAgents: { nodes: [] },
      userAccessAuthorizedAgents: { nodes: [] },
      repository: {
        tree: {
          trees: { nodes: [{ ...agent, path: null }] },
        },
      },
    },
  },
};

export const kasDisabledErrorResponse = {
  data: {},
  errors: [{ message: 'Gitlab::Kas::Client::ConfigurationError' }],
};

export const mockDeleteResponse = {
  data: { clusterAgentDelete: { errors: [] } },
};

export const mockErrorDeleteResponse = {
  data: {
    clusterAgentDelete: {
      errors: ['could not delete agent'],
    },
  },
};
