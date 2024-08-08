import { ACTIVE_CONNECTION_TIME } from '~/clusters_list/constants';

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
        },
        {
          metadata: { version: 'v14.8.0' },
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
        },
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
        },
        {
          metadata: { version: 'v14.3.0' },
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
