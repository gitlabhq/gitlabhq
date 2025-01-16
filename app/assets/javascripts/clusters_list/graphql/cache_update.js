import produce from 'immer';

export const hasErrors = ({ errors = [] }) => errors?.length;

// eslint-disable-next-line max-params
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

// eslint-disable-next-line max-params
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
