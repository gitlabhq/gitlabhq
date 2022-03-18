import produce from 'immer';

export const hasErrors = ({ errors = [] }) => errors?.length;

export function addAgentTokenToStore(store, clusterAgentTokenCreate, query, variables) {
  if (!hasErrors(clusterAgentTokenCreate)) {
    const { token } = clusterAgentTokenCreate;
    const sourceData = store.readQuery({
      query,
      variables,
    });

    const data = produce(sourceData, (draftData) => {
      draftData.project.clusterAgent.tokens.nodes.unshift(token);
      draftData.project.clusterAgent.tokens.count += 1;
    });

    store.writeQuery({
      query,
      variables,
      data,
    });
  }
}
