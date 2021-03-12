import { produce } from 'immer';
import getGroupPackagesSettingsQuery from '../queries/get_group_packages_settings.query.graphql';

export const updateGroupPackageSettings = (fullPath) => (client, { data: updatedData }) => {
  const queryAndParams = {
    query: getGroupPackagesSettingsQuery,
    variables: { fullPath },
  };
  const sourceData = client.readQuery(queryAndParams);

  const data = produce(sourceData, (draftState) => {
    draftState.group.packageSettings = {
      ...updatedData.updateNamespacePackageSettings.packageSettings,
    };
  });

  client.writeQuery({
    ...queryAndParams,
    data,
  });
};
