import { produce } from 'immer';
import getGroupPackagesSettingsQuery from '../queries/get_group_packages_settings.query.graphql';

export const updateGroupPackageSettings =
  (fullPath) =>
  (client, { data: updatedData }) => {
    const queryAndParams = {
      query: getGroupPackagesSettingsQuery,
      variables: { fullPath },
    };
    const sourceData = client.readQuery(queryAndParams);

    const data = produce(sourceData, (draftState) => {
      if (updatedData.updateNamespacePackageSettings) {
        draftState.group.packageSettings = {
          ...updatedData.updateNamespacePackageSettings.packageSettings,
        };
      }
      if (updatedData.updateDependencyProxySettings) {
        draftState.group.dependencyProxySetting = {
          ...updatedData.updateDependencyProxySettings.dependencyProxySetting,
        };
      }
      if (updatedData.updateDependencyProxyImageTtlGroupPolicy) {
        draftState.group.dependencyProxyImageTtlPolicy = {
          ...updatedData.updateDependencyProxyImageTtlGroupPolicy.dependencyProxyImageTtlPolicy,
        };
      }
    });

    client.writeQuery({
      ...queryAndParams,
      data,
    });
  };
