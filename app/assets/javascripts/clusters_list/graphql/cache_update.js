import produce from 'immer';

export const hasErrors = ({ errors = [] }) => errors?.length;

export function addAgentToStore(store, createClusterAgent, query, variables) {
  if (!hasErrors(createClusterAgent)) {
    const { clusterAgent } = createClusterAgent;
    const sourceData = store.readQuery({
      query,
      variables,
    });

    const data = produce(sourceData, (draftData) => {
      draftData.project.clusterAgents.nodes.push(clusterAgent);
      draftData.project.clusterAgents.count += 1;
    });

    store.writeQuery({
      query,
      variables,
      data,
    });
  }
}

export function addAgentConfigToStore(
  store,
  clusterAgentTokenCreate,
  clusterAgent,
  query,
  variables,
) {
  if (!hasErrors(clusterAgentTokenCreate)) {
    const sourceData = store.readQuery({
      query,
      variables,
    });

    const data = produce(sourceData, (draftData) => {
      const configuration = {
        agentName: clusterAgent.name,
        __typename: 'AgentConfiguration',
      };

      draftData.project.clusterAgents.nodes.push(clusterAgent);
      draftData.project.agentConfigurations.nodes.push(configuration);
    });

    store.writeQuery({
      query,
      variables,
      data,
    });
  }
}

export function removeAgentFromStore(store, deleteClusterAgent, query, variables) {
  if (!hasErrors(deleteClusterAgent)) {
    const sourceData = store.readQuery({
      query,
      variables,
    });

    const data = produce(sourceData, (draftData) => {
      draftData.project.clusterAgents.nodes = draftData.project.clusterAgents.nodes.filter(
        ({ id }) => id !== deleteClusterAgent.id,
      );
      draftData.project.clusterAgents.count -= 1;
    });

    store.writeQuery({
      query,
      variables,
      data,
    });
  }
}
