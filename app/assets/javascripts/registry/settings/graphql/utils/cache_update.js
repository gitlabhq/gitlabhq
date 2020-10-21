import { produce } from 'immer';
import expirationPolicyQuery from '../queries/get_expiration_policy.graphql';

export const updateContainerExpirationPolicy = projectPath => (client, { data: updatedData }) => {
  const queryAndParams = {
    query: expirationPolicyQuery,
    variables: { projectPath },
  };
  const sourceData = client.readQuery(queryAndParams);

  const data = produce(sourceData, draftState => {
    // eslint-disable-next-line no-param-reassign
    draftState.project.containerExpirationPolicy = {
      ...updatedData.updateContainerExpirationPolicy.containerExpirationPolicy,
    };
  });

  client.writeQuery({
    ...queryAndParams,
    data,
  });
};
