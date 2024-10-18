import MockAdapter from 'axios-mock-adapter';
import {
  CoreV1Api,
  AppsV1Api,
  WatchApi,
  WebSocketWatchManager,
  EVENT_DATA,
  EVENT_TIMEOUT,
  EVENT_ERROR,
} from '@gitlab/cluster-client';
import axios from '~/lib/utils/axios_utils';
import { resolvers } from '~/environments/graphql/resolvers';
import { CLUSTER_AGENT_ERROR_MESSAGES } from '~/environments/constants';
import k8sPodsQuery from '~/environments/graphql/queries/k8s_pods.query.graphql';
import k8sServicesQuery from '~/environments/graphql/queries/k8s_services.query.graphql';
import k8sDeploymentsQuery from '~/environments/graphql/queries/k8s_deployments.query.graphql';
import k8sEventsQuery from '~/environments/graphql/queries/k8s_events.query.graphql';
import { updateConnectionStatus } from '~/environments/graphql/resolvers/kubernetes/k8s_connection_status';
import {
  connectionStatus,
  k8sResourceType,
} from '~/environments/graphql/resolvers/kubernetes/constants';
import {
  k8sPodsMock,
  k8sServicesMock,
  k8sDeploymentsMock,
  k8sEventsMock,
} from 'jest/kubernetes_dashboard/graphql/mock_data';
import { k8sNamespacesMock } from '../mock_data';
import { bootstrapWatcherMock } from '../watcher_mock_helper';

jest.mock('~/environments/graphql/resolvers/kubernetes/k8s_connection_status');

describe('~/frontend/environments/graphql/resolvers', () => {
  let mockResolvers;
  let mock;

  const configuration = {
    basePath: 'kas-proxy/',
    headers: { 'GitLab-Agent-Id': '1', 'X-CSRF-Token': 'token' },
  };
  const namespace = 'default';

  beforeEach(() => {
    mockResolvers = resolvers();
    mock = new MockAdapter(axios);
    gon.features = {
      useWebsocketForK8sWatch: false,
    };
  });

  afterEach(() => {
    mock.reset();
  });

  describe('k8sPods', () => {
    const client = { writeQuery: jest.fn(), readQuery: jest.fn() };
    const mockPodsListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        items: k8sPodsMock,
      });
    });

    const mockNamespacedPodsListFn = jest.fn().mockImplementation(mockPodsListFn);
    const mockAllPodsListFn = jest.fn().mockImplementation(mockPodsListFn);

    const mockWatcher = WatchApi.prototype;
    const mockPodsListWatcherFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWatcher);
    });

    describe('when the pods data is present', () => {
      let watcherMock;
      beforeEach(() => {
        watcherMock = bootstrapWatcherMock();
        jest
          .spyOn(CoreV1Api.prototype, 'listCoreV1NamespacedPod')
          .mockImplementation(mockNamespacedPodsListFn);
        jest
          .spyOn(CoreV1Api.prototype, 'listCoreV1PodForAllNamespaces')
          .mockImplementation(mockAllPodsListFn);
      });

      it.each([
        [null, connectionStatus.connecting],
        [EVENT_DATA, connectionStatus.connected],
        [EVENT_TIMEOUT, connectionStatus.disconnected],
        [EVENT_ERROR, connectionStatus.disconnected],
      ])(
        'when "%s" event is received should update k8s connection status to "%s"',
        async (eventName, expectedStatus) => {
          await mockResolvers.Query.k8sPods(null, { configuration, namespace }, { client });

          if (eventName) {
            watcherMock.triggerEvent(eventName, []);
          }

          expect(updateConnectionStatus).toHaveBeenCalledWith(expect.anything(), {
            configuration,
            namespace,
            resourceType: k8sResourceType.k8sPods,
            status: expectedStatus,
          });
        },
      );

      it('should request namespaced pods from the cluster_client library if namespace is specified', async () => {
        await mockResolvers.Query.k8sPods(null, { configuration, namespace }, { client });

        expect(watcherMock.subscribeToStreamMock).toHaveBeenCalledWith(
          `/api/v1/namespaces/${namespace}/pods`,
          {
            watch: true,
          },
        );
      });
      it('should request all pods from the cluster_client library if namespace is not specified', async () => {
        await mockResolvers.Query.k8sPods(null, { configuration, namespace: '' }, { client });

        expect(watcherMock.subscribeToStreamMock).toHaveBeenCalledWith(`/api/v1/pods`, {
          watch: true,
        });
      });
      it('should update cache with the new data when received from the library', async () => {
        await mockResolvers.Query.k8sPods(null, { configuration, namespace: '' }, { client });

        watcherMock.triggerEvent(EVENT_DATA, []);

        expect(client.writeQuery).toHaveBeenCalledWith({
          query: k8sPodsQuery,
          variables: { configuration, namespace: '' },
          data: { k8sPods: [] },
        });
      });

      describe('when `useWebsocketForK8sWatch` feature is enabled', () => {
        const mockWebsocketManager = WebSocketWatchManager.prototype;
        const mockInitConnectionFn = jest.fn().mockImplementation(() => {
          return Promise.resolve(mockWebsocketManager);
        });

        beforeEach(() => {
          gon.features = {
            useWebsocketForK8sWatch: true,
          };

          jest
            .spyOn(mockWebsocketManager, 'initConnection')
            .mockImplementation(mockInitConnectionFn);
          jest.spyOn(mockWebsocketManager, 'on').mockImplementation(jest.fn());
        });

        it('calls websocket API', async () => {
          await mockResolvers.Query.k8sPods(null, { configuration, namespace }, { client });

          expect(mockInitConnectionFn).toHaveBeenCalledWith({
            configuration,
            message: {
              watchId: `k8sPods-n-${namespace}`,
              watchParams: {
                namespace,
                resource: 'pods',
                version: 'v1',
              },
            },
          });
        });

        it("doesn't call watch API", async () => {
          await mockResolvers.Query.k8sPods(null, { configuration, namespace }, { client });

          expect(CoreV1Api.prototype.listCoreV1NamespacedPod).toHaveBeenCalled();
          expect(mockPodsListWatcherFn).not.toHaveBeenCalled();
        });
      });
    });

    it('should not watch pods from the cluster_client library when the pods data is not present', async () => {
      jest.spyOn(CoreV1Api.prototype, 'listCoreV1NamespacedPod').mockImplementation(
        jest.fn().mockImplementation(() => {
          return Promise.resolve({
            items: [],
          });
        }),
      );

      await mockResolvers.Query.k8sPods(null, { configuration, namespace }, { client });

      expect(mockPodsListWatcherFn).not.toHaveBeenCalled();
    });

    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(CoreV1Api.prototype, 'listCoreV1PodForAllNamespaces')
        .mockRejectedValue(new Error('API error'));

      await expect(
        mockResolvers.Query.k8sPods(null, { configuration }, { client }),
      ).rejects.toThrow('API error');
    });
  });
  describe('k8sServices', () => {
    const client = { writeQuery: jest.fn() };
    const mockServicesListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        items: k8sServicesMock,
      });
    });

    const mockNamespacedServicesListFn = jest.fn().mockImplementation(mockServicesListFn);
    const mockAllServicesListFn = jest.fn().mockImplementation(mockServicesListFn);

    const mockWatcher = WatchApi.prototype;
    const mockServicesListWatcherFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWatcher);
    });

    const mockOnDataFn = jest.fn().mockImplementation((eventName, callback) => {
      if (eventName === 'data') {
        callback([]);
      }
    });

    describe('when the services data is present', () => {
      beforeEach(() => {
        jest
          .spyOn(CoreV1Api.prototype, 'listCoreV1NamespacedService')
          .mockImplementation(mockNamespacedServicesListFn);
        jest
          .spyOn(CoreV1Api.prototype, 'listCoreV1ServiceForAllNamespaces')
          .mockImplementation(mockAllServicesListFn);
        jest.spyOn(mockWatcher, 'subscribeToStream').mockImplementation(mockServicesListWatcherFn);
        jest.spyOn(mockWatcher, 'on').mockImplementation(mockOnDataFn);
      });

      it('should request namespaced services from the cluster_client library if namespace is specified', async () => {
        await mockResolvers.Query.k8sServices(null, { configuration, namespace }, { client });

        expect(mockServicesListWatcherFn).toHaveBeenCalledWith(
          `/api/v1/namespaces/${namespace}/services`,
          {
            watch: true,
          },
        );
      });
      it('should request all services from the cluster_client library if namespace is not specified', async () => {
        await mockResolvers.Query.k8sServices(null, { configuration, namespace: '' }, { client });

        expect(mockServicesListWatcherFn).toHaveBeenCalledWith(`/api/v1/services`, {
          watch: true,
        });
      });
      it('should update cache with the new data when received from the library', async () => {
        await mockResolvers.Query.k8sServices(null, { configuration, namespace: '' }, { client });

        expect(client.writeQuery).toHaveBeenCalledWith({
          query: k8sServicesQuery,
          variables: { configuration, namespace: '' },
          data: { k8sServices: [] },
        });
      });

      describe('when `useWebsocketForK8sWatch` feature is enabled', () => {
        const mockWebsocketManager = WebSocketWatchManager.prototype;
        const mockInitConnectionFn = jest.fn().mockImplementation(() => {
          return Promise.resolve(mockWebsocketManager);
        });

        beforeEach(() => {
          gon.features = {
            useWebsocketForK8sWatch: true,
          };

          jest
            .spyOn(mockWebsocketManager, 'initConnection')
            .mockImplementation(mockInitConnectionFn);
          jest.spyOn(mockWebsocketManager, 'on').mockImplementation(jest.fn());
        });

        it('calls websocket API', async () => {
          await mockResolvers.Query.k8sServices(null, { configuration, namespace }, { client });

          expect(mockInitConnectionFn).toHaveBeenCalledWith({
            configuration,
            message: {
              watchId: `k8sServices-n-${namespace}`,
              watchParams: {
                namespace,
                resource: 'services',
                version: 'v1',
              },
            },
          });
        });

        it("doesn't call watch API", async () => {
          await mockResolvers.Query.k8sServices(null, { configuration, namespace }, { client });

          expect(CoreV1Api.prototype.listCoreV1NamespacedService).toHaveBeenCalled();
          expect(mockServicesListWatcherFn).not.toHaveBeenCalled();
        });
      });
    });

    it('should not watch services from the cluster_client library when the services data is not present', async () => {
      jest.spyOn(CoreV1Api.prototype, 'listCoreV1NamespacedService').mockImplementation(
        jest.fn().mockImplementation(() => {
          return Promise.resolve({
            items: [],
          });
        }),
      );

      await mockResolvers.Query.k8sServices(null, { configuration, namespace }, { client });

      expect(mockServicesListWatcherFn).not.toHaveBeenCalled();
    });

    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(CoreV1Api.prototype, 'listCoreV1ServiceForAllNamespaces')
        .mockRejectedValue(new Error('API error'));

      await expect(
        mockResolvers.Query.k8sServices(null, { configuration }, { client }),
      ).rejects.toThrow('API error');
    });
  });
  describe('k8sDeployments', () => {
    const client = { writeQuery: jest.fn() };
    const mockDeploymentsListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        items: k8sDeploymentsMock,
      });
    });

    const mockNamespacedDeploymentsListFn = jest.fn().mockImplementation(mockDeploymentsListFn);
    const mockAllDeploymentsListFn = jest.fn().mockImplementation(mockDeploymentsListFn);

    const mockWatcher = WatchApi.prototype;
    const mockDeploymentsListWatcherFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWatcher);
    });

    const mockOnDataFn = jest.fn().mockImplementation((eventName, callback) => {
      if (eventName === 'data') {
        callback([]);
      }
    });

    describe('when the deployments data is present', () => {
      beforeEach(() => {
        jest
          .spyOn(AppsV1Api.prototype, 'listAppsV1NamespacedDeployment')
          .mockImplementation(mockNamespacedDeploymentsListFn);
        jest
          .spyOn(AppsV1Api.prototype, 'listAppsV1DeploymentForAllNamespaces')
          .mockImplementation(mockAllDeploymentsListFn);
        jest
          .spyOn(mockWatcher, 'subscribeToStream')
          .mockImplementation(mockDeploymentsListWatcherFn);
        jest.spyOn(mockWatcher, 'on').mockImplementation(mockOnDataFn);
      });

      it('should request namespaced deployments from the cluster_client library if namespace is specified', async () => {
        await mockResolvers.Query.k8sDeployments(null, { configuration, namespace }, { client });

        expect(mockDeploymentsListWatcherFn).toHaveBeenCalledWith(
          `/apis/apps/v1/namespaces/${namespace}/deployments`,
          {
            watch: true,
          },
        );
      });
      it('should request all deployments from the cluster_client library if namespace is not specified', async () => {
        await mockResolvers.Query.k8sDeployments(
          null,
          { configuration, namespace: '' },
          { client },
        );

        expect(mockDeploymentsListWatcherFn).toHaveBeenCalledWith(`/apis/apps/v1/deployments`, {
          watch: true,
        });
      });
      it('should update cache with the new data when received from the library', async () => {
        await mockResolvers.Query.k8sDeployments(
          null,
          { configuration, namespace: '' },
          { client },
        );

        expect(client.writeQuery).toHaveBeenCalledWith({
          query: k8sDeploymentsQuery,
          variables: { configuration, namespace: '' },
          data: { k8sDeployments: [] },
        });
      });
    });

    it('should not watch deployments from the cluster_client library when the services data is not present', async () => {
      jest.spyOn(AppsV1Api.prototype, 'listAppsV1NamespacedDeployment').mockImplementation(
        jest.fn().mockImplementation(() => {
          return Promise.resolve({
            items: [],
          });
        }),
      );

      await mockResolvers.Query.k8sDeployments(null, { configuration, namespace }, { client });

      expect(mockDeploymentsListWatcherFn).not.toHaveBeenCalled();
    });

    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(AppsV1Api.prototype, 'listAppsV1DeploymentForAllNamespaces')
        .mockRejectedValue(new Error('API error'));

      await expect(
        mockResolvers.Query.k8sDeployments(null, { configuration }, { client }),
      ).rejects.toThrow('API error');
    });
  });
  describe('k8sNamespaces', () => {
    const mockNamespacesListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        items: k8sNamespacesMock,
      });
    });

    beforeEach(() => {
      jest
        .spyOn(CoreV1Api.prototype, 'listCoreV1Namespace')
        .mockImplementation(mockNamespacesListFn);
    });

    it('should request all namespaces from the cluster_client library', async () => {
      const namespaces = await mockResolvers.Query.k8sNamespaces(null, { configuration });

      expect(mockNamespacesListFn).toHaveBeenCalled();

      expect(namespaces).toEqual(k8sNamespacesMock);
    });
    it.each([
      ['Unauthorized', CLUSTER_AGENT_ERROR_MESSAGES.unauthorized],
      ['Forbidden', CLUSTER_AGENT_ERROR_MESSAGES.forbidden],
      ['Not found', CLUSTER_AGENT_ERROR_MESSAGES['not found']],
      ['Unknown', CLUSTER_AGENT_ERROR_MESSAGES.other],
    ])(
      'should throw an error if the API call fails with the reason "%s"',
      async (reason, message) => {
        jest.spyOn(CoreV1Api.prototype, 'listCoreV1Namespace').mockRejectedValue({ reason });

        await expect(mockResolvers.Query.k8sNamespaces(null, { configuration })).rejects.toThrow(
          message,
        );
      },
    );
  });

  describe('k8sEvents', () => {
    const client = { writeQuery: jest.fn() };

    const involvedObjectName = 'my-pod';
    const mockEventsListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        items: k8sEventsMock,
      });
    });

    const mockWatcher = WatchApi.prototype;
    const mockEventsListWatcherFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWatcher);
    });

    const mockOnDataFn = jest.fn().mockImplementation((eventName, callback) => callback([]));

    describe('when the API request is successful', () => {
      beforeEach(() => {
        jest
          .spyOn(CoreV1Api.prototype, 'listCoreV1NamespacedEvent')
          .mockImplementation(mockEventsListFn);
        jest.spyOn(mockWatcher, 'subscribeToStream').mockImplementation(mockEventsListWatcherFn);
        jest.spyOn(mockWatcher, 'on').mockImplementation(mockOnDataFn);
      });

      it('should request namespaced events with the field selector from the cluster_client library if namespace is specified', async () => {
        const events = await mockResolvers.Query.k8sEvents(
          null,
          {
            configuration,
            namespace,
            involvedObjectName,
          },
          { client },
        );

        expect(mockEventsListFn).toHaveBeenCalledWith({
          namespace,
          fieldSelector: `involvedObject.name=${involvedObjectName}`,
        });
        expect(events).toEqual(k8sEventsMock);
      });

      it('should update cache with the new data when received from the library', async () => {
        await mockResolvers.Query.k8sEvents(
          null,
          {
            configuration,
            namespace,
            involvedObjectName,
          },
          { client },
        );

        expect(client.writeQuery).toHaveBeenCalledWith({
          query: k8sEventsQuery,
          variables: { configuration, namespace, involvedObjectName },
          data: { k8sEvents: [] },
        });
      });

      describe('when `useWebsocketForK8sWatch` feature is enabled', () => {
        const mockWebsocketManager = WebSocketWatchManager.prototype;
        const mockInitConnectionFn = jest.fn().mockImplementation(() => {
          return Promise.resolve(mockWebsocketManager);
        });

        beforeEach(() => {
          gon.features = {
            useWebsocketForK8sWatch: true,
          };

          jest
            .spyOn(mockWebsocketManager, 'initConnection')
            .mockImplementation(mockInitConnectionFn);
          jest.spyOn(mockWebsocketManager, 'on').mockImplementation(jest.fn());
        });

        it('calls websocket API', async () => {
          await mockResolvers.Query.k8sEvents(
            null,
            { configuration, namespace, involvedObjectName },
            { client },
          );

          expect(mockInitConnectionFn).toHaveBeenCalledWith({
            configuration,
            message: {
              watchId: `events-io-${involvedObjectName}`,
              watchParams: {
                namespace,
                resource: 'events',
                fieldSelector: `involvedObject.name=${involvedObjectName}`,
                version: 'v1',
              },
            },
          });
        });

        it("doesn't call watch API", async () => {
          await mockResolvers.Query.k8sEvents(
            null,
            { configuration, namespace, involvedObjectName },
            { client },
          );

          expect(CoreV1Api.prototype.listCoreV1NamespacedEvent).toHaveBeenCalled();
          expect(mockEventsListWatcherFn).not.toHaveBeenCalled();
        });
      });
    });

    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(CoreV1Api.prototype, 'listCoreV1NamespacedEvent')
        .mockRejectedValue(new Error('API error'));

      await expect(
        mockResolvers.Query.k8sEvents(
          null,
          { configuration, namespace, involvedObjectName },
          { client },
        ),
      ).rejects.toThrow('API error');
    });
  });

  describe('deleteKubernetesPod', () => {
    const mockPodsDeleteFn = jest.fn().mockResolvedValue({ errors: [] });
    const podToDelete = 'my-pod';

    it('should request delete pod API from the cluster_client library', async () => {
      jest
        .spyOn(CoreV1Api.prototype, 'deleteCoreV1NamespacedPod')
        .mockImplementation(mockPodsDeleteFn);

      const result = await mockResolvers.Mutation.deleteKubernetesPod(null, {
        configuration,
        namespace,
        podName: podToDelete,
      });

      expect(mockPodsDeleteFn).toHaveBeenCalledWith({ name: podToDelete, namespace });
      expect(result).toEqual({
        __typename: 'LocalKubernetesErrors',
        errors: [],
      });
    });

    it('should return errors array if the API call fails', async () => {
      jest
        .spyOn(CoreV1Api.prototype, 'deleteCoreV1NamespacedPod')
        .mockRejectedValue({ message: CLUSTER_AGENT_ERROR_MESSAGES['not found'] });

      const result = await mockResolvers.Mutation.deleteKubernetesPod(null, {
        configuration,
        namespace,
        podName: podToDelete,
      });

      expect(result).toEqual({
        __typename: 'LocalKubernetesErrors',
        errors: [CLUSTER_AGENT_ERROR_MESSAGES['not found']],
      });
    });
  });
});
