import { ACTIVE_CONNECTION_TIME } from '~/clusters_list/constants';
import { agent, tokens, connections } from '../mocks/apollo';

export const agentConfigurationsResponse = {
  data: {
    project: {
      agentConfigurations: {
        nodes: [{ agentName: 'installed-agent' }, { agentName: 'configured-agent' }],
      },
      clusterAgents: {
        nodes: [{ name: 'installed-agent' }],
      },
    },
  },
};

export const connectedTimeNow = new Date();
export const connectedTimeInactive = new Date(connectedTimeNow.getTime() - ACTIVE_CONNECTION_TIME);

export const clusterAgents = [
  {
    name: 'agent-1',
    id: 'gid://gitlab/Clusters::Agent/1',
    configFolder: {
      webPath: '/agent/full/path',
    },
    webPath: '/agent-1',
    status: 'unused',
    lastContact: null,
    project: {
      fullPath: 'path/to/project',
    },
    userAccessAuthorizations: {
      config: {
        access_as: { agent: {} },
      },
    },
    tokens: null,
  },
  {
    name: 'agent-2',
    id: 'gid://gitlab/Clusters::Agent/2',
    webPath: '/agent-2',
    status: 'active',
    lastContact: connectedTimeNow.getTime(),
    project: {
      fullPath: 'path/to/project',
    },
    userAccessAuthorizations: null,
    connections: {
      nodes: [
        {
          metadata: { version: 'v14.8.0' },
          warnings: [],
        },
        {
          metadata: { version: 'v14.8.0' },
          warnings: [],
        },
      ],
    },
    tokens: {
      nodes: [
        {
          lastUsedAt: connectedTimeNow,
        },
      ],
    },
  },
  {
    name: 'agent-3',
    id: 'gid://gitlab/Clusters::Agent/3',
    webPath: '/agent-3',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
    userAccessAuthorizations: null,
    project: {
      fullPath: 'path/to/project',
    },
    connections: {
      nodes: [
        {
          metadata: { version: 'v14.6.0' },
          warnings: [{ version: { message: 'This agent is outdated' } }],
        },
      ],
    },
    tokens: {
      nodes: [
        {
          lastUsedAt: connectedTimeInactive,
        },
      ],
    },
  },
  {
    name: 'agent-4',
    id: 'gid://gitlab/Clusters::Agent/4',
    webPath: '/agent-4',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
    project: {
      fullPath: 'path/to/project',
    },
    userAccessAuthorizations: null,
    connections: {
      nodes: [
        {
          metadata: { version: 'v14.7.0' },
          warnings: [],
        },
        {
          metadata: { version: 'v14.8.0' },
          warnings: [],
        },
      ],
    },
    tokens: {
      nodes: [
        {
          lastUsedAt: connectedTimeInactive,
        },
      ],
    },
  },
  {
    name: 'agent-5',
    id: 'gid://gitlab/Clusters::Agent/5',
    webPath: '/agent-5',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
    project: {
      fullPath: 'path/to/project',
    },
    userAccessAuthorizations: null,
    connections: {
      nodes: [
        {
          metadata: { version: 'v14.5.0' },
          warnings: [{ version: { message: 'This agent is outdated' } }],
        },
        {
          metadata: { version: 'v14.3.0' },
          warnings: [{ version: { message: 'This agent is outdated' } }],
        },
      ],
    },
    tokens: {
      nodes: [
        {
          lastUsedAt: connectedTimeInactive,
        },
      ],
    },
  },
  {
    name: 'agent-6',
    id: 'gid://gitlab/Clusters::Agent/6',
    webPath: '/agent-6',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
    project: {
      fullPath: 'path/to/project',
    },
    userAccessAuthorizations: null,
    connections: {
      nodes: [
        {
          metadata: { version: 'v14.6.0' },
        },
      ],
    },
    tokens: {
      nodes: [
        {
          lastUsedAt: connectedTimeInactive,
        },
      ],
    },
  },
  {
    name: 'agent-7',
    id: 'gid://gitlab/Clusters::Agent/7',
    webPath: '/agent-7',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
    project: {
      fullPath: 'path/to/project',
    },
    userAccessAuthorizations: null,
    connections: {
      nodes: [
        {
          metadata: { version: 'v14.8.0' },
        },
      ],
    },
    tokens: {
      nodes: [
        {
          lastUsedAt: connectedTimeInactive,
        },
      ],
    },
  },
  {
    name: 'agent-8',
    id: 'gid://gitlab/Clusters::Agent/8',
    webPath: '/agent-8',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
    project: {
      fullPath: 'path/to/project',
    },
    userAccessAuthorizations: null,
    connections: {
      nodes: [
        {
          metadata: { version: 'v14.8.0' },
        },
      ],
    },
    tokens: {
      nodes: [
        {
          lastUsedAt: connectedTimeInactive,
        },
      ],
    },
  },
  {
    name: 'agent-9',
    id: 'gid://gitlab/Clusters::Agent/9',
    webPath: '/agent-9',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
    project: {
      fullPath: 'path/to/project',
    },
    userAccessAuthorizations: null,
    connections: {
      nodes: [
        {
          metadata: { version: 'v14.8.0' },
        },
      ],
    },
    tokens: {
      nodes: [
        {
          lastUsedAt: connectedTimeInactive,
        },
      ],
    },
  },
  {
    name: 'ci-agent-1',
    id: '3',
    webPath: 'shared-project/agent-1',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
    project: {
      fullPath: 'path/to/project',
    },
    userAccessAuthorizations: null,
    isShared: true,
    connections: null,
    tokens: null,
  },
];

const agentProject = {
  id: '1',
  fullPath: 'path/to/project',
};

const timestamp = '2023-05-12T15:39:58Z';

const agents = [
  {
    __typename: 'ClusterAgent',
    id: '1',
    name: 'agent-1',
    webPath: '/agent-1',
    createdAt: timestamp,
    userAccessAuthorizations: null,
    connections: null,
    tokens: null,
    project: agentProject,
  },
  {
    __typename: 'ClusterAgent',
    id: '2',
    name: 'agent-2',
    webPath: '/agent-2',
    createdAt: timestamp,
    userAccessAuthorizations: null,
    connections: null,
    tokens: {
      nodes: [
        {
          id: 'token-1',
          lastUsedAt: timestamp,
        },
      ],
    },
    project: agentProject,
  },
];
const ciAccessAuthorizedAgentsNodes = [
  {
    agent: {
      __typename: 'ClusterAgent',
      id: '3',
      name: 'ci-agent-1',
      webPath: 'shared-project/agent-1',
      createdAt: timestamp,
      userAccessAuthorizations: null,
      connections: null,
      tokens: null,
      project: { id: '2', fullPath: 'path/to/another/project' },
    },
  },
];
const userAccessAuthorizedAgentsNodes = [
  {
    agent: {
      __typename: 'ClusterAgent',
      id: '4',
      name: 'user-access-agent-1',
      webPath: 'shared-project/agent-1',
      createdAt: timestamp,
      userAccessAuthorizations: null,
      connections: null,
      tokens: null,
      project: { id: '2', fullPath: 'path/to/another/project' },
    },
  },
];

export const clusterAgentsResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      clusterAgents: {
        nodes: agents,
        count: agents.length,
      },
    },
  },
};

export const sharedAgentsResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      ciAccessAuthorizedAgents: {
        nodes: ciAccessAuthorizedAgentsNodes,
      },
      userAccessAuthorizedAgents: {
        nodes: userAccessAuthorizedAgentsNodes,
      },
    },
  },
};

const trees = [
  {
    id: 'tree-1',
    name: 'agent-2',
    path: '.gitlab/agents/agent-2',
    webPath: '/project/path/.gitlab/agents/agent-2',
  },
  {
    id: 'tree-2',
    name: 'new-agent-2',
    path: '.gitlab/agents/new-agent-2',
    webPath: '/project/path/.gitlab/agents/new-agent-2',
  },
];

export const treeListResponseData = {
  data: {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      repository: {
        tree: {
          trees: { nodes: trees },
        },
      },
    },
  },
};

export const expectedAgentsList = [
  {
    id: '2',
    name: 'agent-2',
    configFolder: {
      name: 'agent-2',
      path: '.gitlab/agents/agent-2',
      webPath: '/project/path/.gitlab/agents/agent-2',
    },
    webPath: '/agent-2',
    status: 'active',
    lastContact: new Date(timestamp).getTime(),
    connections: null,
    tokens: {
      nodes: [
        {
          lastUsedAt: timestamp,
        },
      ],
    },
    project: agentProject,
  },
  {
    id: '1',
    name: 'agent-1',
    webPath: '/agent-1',
    configFolder: undefined,
    status: 'unused',
    lastContact: null,
    connections: null,
    tokens: null,
    project: agentProject,
  },
];

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
