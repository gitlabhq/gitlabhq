import produce from 'immer';

export const hasErrors = ({ errors = [] }) => errors?.length;

// eslint-disable-next-line max-params
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

// eslint-disable-next-line max-params
export function removeTokenFromStore(store, revokeToken, query, variables) {
  if (!hasErrors(revokeToken)) {
    const sourceData = store.readQuery({
      query,
      variables,
    });

    const data = produce(sourceData, (draftData) => {
      draftData.project.clusterAgent.tokens.nodes =
        draftData.project.clusterAgent.tokens.nodes.filter(({ id }) => id !== revokeToken.id);
      draftData.project.clusterAgent.tokens.count -= 1;
    });

    store.writeQuery({
      query,
      variables,
      data,
    });
  }
}
