import produce from 'immer';

export const hasErrors = ({ errors = [] }) => errors?.length;

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
      draftData.project.ciAccessAuthorizedAgents.nodes = draftData.project.ciAccessAuthorizedAgents.nodes.filter(
        ({ agent }) => agent.id !== deleteClusterAgent.id,
      );
      draftData.project.userAccessAuthorizedAgents.nodes = draftData.project.userAccessAuthorizedAgents.nodes.filter(
        ({ agent }) => agent.id !== deleteClusterAgent.id,
      );
    });

    store.writeQuery({
      query,
      variables,
      data,
    });
  }
}
