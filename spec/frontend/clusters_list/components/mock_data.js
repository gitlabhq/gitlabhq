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
    id: 'agent-1-id',
    configFolder: {
      webPath: '/agent/full/path',
    },
    webPath: '/agent-1',
    status: 'unused',
    lastContact: null,
    tokens: null,
  },
  {
    name: 'agent-2',
    id: 'agent-2-id',
    webPath: '/agent-2',
    status: 'active',
    lastContact: connectedTimeNow.getTime(),
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
    id: 'agent-3-id',
    webPath: '/agent-3',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
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
    id: 'agent-4-id',
    webPath: '/agent-4',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
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
    id: 'agent-5-id',
    webPath: '/agent-5',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
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
    id: 'agent-6-id',
    webPath: '/agent-6',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
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
    id: 'agent-7-id',
    webPath: '/agent-7',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
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
    id: 'agent-8-id',
    webPath: '/agent-8',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
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
    id: 'agent-9-id',
    webPath: '/agent-9',
    status: 'inactive',
    lastContact: connectedTimeInactive.getTime(),
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
];
