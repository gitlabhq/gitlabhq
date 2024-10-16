import { produce } from 'immer';
import expirationPolicyQuery from '../queries/get_expiration_policy.query.graphql';

export const updateContainerExpirationPolicy =
  (projectPath) =>
  (client, { data: updatedData }) => {
    const queryAndParams = {
      query: expirationPolicyQuery,
      variables: { projectPath },
    };
    const sourceData = client.readQuery(queryAndParams);

    const data = produce(sourceData, (draftState) => {
      draftState.project.containerTagsExpirationPolicy = {
        ...draftState.project.containerTagsExpirationPolicy,
        ...updatedData.updateContainerExpirationPolicy.containerTagsExpirationPolicy,
      };
    });

    client.writeQuery({
      ...queryAndParams,
      data,
    });
  };
