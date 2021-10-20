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
