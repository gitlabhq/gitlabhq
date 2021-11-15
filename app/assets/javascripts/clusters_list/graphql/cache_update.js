import produce from 'immer';
import { getAgentConfigPath } from '../clusters_util';

export function addAgentToStore(store, createClusterAgent, query, variables) {
  const { clusterAgent } = createClusterAgent;
  const sourceData = store.readQuery({
    query,
    variables,
  });

  const data = produce(sourceData, (draftData) => {
    const configuration = {
      name: clusterAgent.name,
      path: getAgentConfigPath(clusterAgent.name),
      webPath: clusterAgent.webPath,
      __typename: 'TreeEntry',
    };

    draftData.project.clusterAgents.nodes.push(clusterAgent);
    draftData.project.clusterAgents.count += 1;
    draftData.project.repository.tree.trees.nodes.push(configuration);
  });

  store.writeQuery({
    query,
    variables,
    data,
  });
}
