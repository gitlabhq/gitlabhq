export const agent = {
  __typename: 'ClusterAgent',
  id: 'agent-id',
  name: 'agent-name',
  webPath: 'agent-webPath',
  createdAt: new Date(),
  userAccessAuthorizations: null,
  project: {
    id: '1',
    fullPath: 'path/to/project',
  },
};
const token = {
  id: 'token-id',
  lastUsedAt: null,
};
export const tokens = {
  nodes: [token],
};
export const connections = {
  nodes: [],
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
