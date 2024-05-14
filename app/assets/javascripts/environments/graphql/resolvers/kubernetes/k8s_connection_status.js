import {
  connectionStatus,
  k8sResourceType,
} from '~/environments/graphql/resolvers/kubernetes/constants';
import k8sConnectionStatusQuery from '~/environments/graphql/queries/k8s_connection_status.query.graphql';

export const updateConnectionStatus = (client, params) => {
  const { configuration, namespace, resourceType, status } = params;
  const statusData = client.readQuery({
    query: k8sConnectionStatusQuery,
    variables: { configuration, namespace },
  })?.k8sConnection || {
    [k8sResourceType.k8sPods]: {
      connectionStatus: connectionStatus.disconnected,
    },
    [k8sResourceType.k8sServices]: {
      connectionStatus: connectionStatus.disconnected,
    },
    [k8sResourceType.fluxKustomizations]: {
      connectionStatus: connectionStatus.disconnected,
    },
    [k8sResourceType.fluxHelmReleases]: {
      connectionStatus: connectionStatus.disconnected,
    },
  };

  const updatedStatusData = {
    ...statusData,
    [resourceType]: { connectionStatus: status },
  };

  client.writeQuery({
    query: k8sConnectionStatusQuery,
    variables: { configuration, namespace },
    data: {
      k8sConnection: updatedStatusData,
    },
  });
};
