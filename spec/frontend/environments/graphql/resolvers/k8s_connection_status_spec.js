import {
  connectionStatus,
  k8sResourceType,
} from '~/environments/graphql/resolvers/kubernetes/constants';
import { updateConnectionStatus } from '~/environments/graphql/resolvers/kubernetes/k8s_connection_status';
import k8sConnectionStatusQuery from '~/environments/graphql/queries/k8s_connection_status.query.graphql';

describe('~/environments/environment_details/graphql/resolvers/k8s_connection_status.', () => {
  describe('updateConnectionStatus', () => {
    const clientMock = {
      writeQuery: jest.fn(),
      readQuery: jest.fn(),
    };

    const configuration = { foo: 'bar' };
    const namespace = 'mock-namespace';

    const statusServicesConnected = {
      [k8sResourceType.k8sServices]: {
        connectionStatus: connectionStatus.connected,
      },
      [k8sResourceType.k8sPods]: {
        connectionStatus: connectionStatus.disconnected,
      },
      [k8sResourceType.fluxKustomizations]: {
        connectionStatus: connectionStatus.disconnected,
      },
      [k8sResourceType.fluxHelmReleases]: {
        connectionStatus: connectionStatus.disconnected,
      },
    };

    const statusPodsConnecting = {
      [k8sResourceType.k8sServices]: {
        connectionStatus: connectionStatus.disconnected,
      },
      [k8sResourceType.k8sPods]: {
        connectionStatus: connectionStatus.connecting,
      },
      [k8sResourceType.fluxKustomizations]: {
        connectionStatus: connectionStatus.disconnected,
      },
      [k8sResourceType.fluxHelmReleases]: {
        connectionStatus: connectionStatus.disconnected,
      },
    };

    it.each([
      [k8sResourceType.k8sServices, connectionStatus.connected, statusServicesConnected],
      [k8sResourceType.k8sPods, connectionStatus.connecting, statusPodsConnecting],
    ])(
      'should update the connection status for %s to %s',
      (resourceType, status, expectedConnectionStatus) => {
        const params = {
          configuration,
          namespace,
          resourceType,
          status,
        };
        updateConnectionStatus(clientMock, params);

        expect(clientMock.writeQuery).toHaveBeenCalledWith({
          query: k8sConnectionStatusQuery,
          variables: {
            configuration,
            namespace,
          },
          data: {
            k8sConnection: expectedConnectionStatus,
          },
        });
      },
    );
  });
});
