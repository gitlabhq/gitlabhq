import { CoreV1Api, WatchApi, AppsV1Api } from '@gitlab/cluster-client';
import { resolvers } from '~/kubernetes_dashboard/graphql/resolvers';
import k8sDashboardPodsQuery from '~/kubernetes_dashboard/graphql/queries/k8s_dashboard_pods.query.graphql';
import k8sDashboardDeploymentsQuery from '~/kubernetes_dashboard/graphql/queries/k8s_dashboard_deployments.query.graphql';
import k8sDashboardStatefulSetsQuery from '~/kubernetes_dashboard/graphql/queries/k8s_dashboard_stateful_sets.query.graphql';
import k8sDashboardReplicaSetsQuery from '~/kubernetes_dashboard/graphql/queries/k8s_dashboard_replica_sets.query.graphql';
import {
  k8sPodsMock,
  k8sDeploymentsMock,
  k8sStatefulSetsMock,
  k8sReplicaSetsMock,
} from '../mock_data';

describe('~/frontend/environments/graphql/resolvers', () => {
  let mockResolvers;

  const configuration = {
    basePath: 'kas-proxy/',
    baseOptions: {
      headers: { 'GitLab-Agent-Id': '1' },
    },
  };

  beforeEach(() => {
    mockResolvers = resolvers;
  });

  describe('k8sPods', () => {
    const client = { writeQuery: jest.fn() };

    const mockWatcher = WatchApi.prototype;
    const mockPodsListWatcherFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWatcher);
    });

    const mockOnDataFn = jest.fn().mockImplementation((eventName, callback) => {
      if (eventName === 'data') {
        callback([]);
      }
    });

    const mockPodsListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        items: k8sPodsMock,
      });
    });

    const mockAllPodsListFn = jest.fn().mockImplementation(mockPodsListFn);

    describe('when the pods data is present', () => {
      beforeEach(() => {
        jest
          .spyOn(CoreV1Api.prototype, 'listCoreV1PodForAllNamespaces')
          .mockImplementation(mockAllPodsListFn);
        jest.spyOn(mockWatcher, 'subscribeToStream').mockImplementation(mockPodsListWatcherFn);
        jest.spyOn(mockWatcher, 'on').mockImplementation(mockOnDataFn);
      });

      it('should request all pods from the cluster_client library and watch the events', async () => {
        const pods = await mockResolvers.Query.k8sPods(
          null,
          {
            configuration,
          },
          { client },
        );

        expect(mockAllPodsListFn).toHaveBeenCalled();
        expect(mockPodsListWatcherFn).toHaveBeenCalled();

        expect(pods).toEqual(k8sPodsMock);
      });

      it('should update cache with the new data when received from the library', async () => {
        await mockResolvers.Query.k8sPods(null, { configuration, namespace: '' }, { client });

        expect(client.writeQuery).toHaveBeenCalledWith({
          query: k8sDashboardPodsQuery,
          variables: { configuration, namespace: '' },
          data: { k8sPods: [] },
        });
      });
    });

    it('should not watch pods from the cluster_client library when the pods data is not present', async () => {
      jest.spyOn(CoreV1Api.prototype, 'listCoreV1PodForAllNamespaces').mockImplementation(
        jest.fn().mockImplementation(() => {
          return Promise.resolve({
            items: [],
          });
        }),
      );

      await mockResolvers.Query.k8sPods(null, { configuration }, { client });

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

  describe('k8sDeployments', () => {
    const client = { writeQuery: jest.fn() };

    const mockWatcher = WatchApi.prototype;
    const mockDeploymentsListWatcherFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWatcher);
    });

    const mockOnDataFn = jest.fn().mockImplementation((eventName, callback) => {
      if (eventName === 'data') {
        callback([]);
      }
    });

    const mockDeploymentsListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        items: k8sDeploymentsMock,
      });
    });

    const mockAllDeploymentsListFn = jest.fn().mockImplementation(mockDeploymentsListFn);

    describe('when the deployments data is present', () => {
      beforeEach(() => {
        jest
          .spyOn(AppsV1Api.prototype, 'listAppsV1DeploymentForAllNamespaces')
          .mockImplementation(mockAllDeploymentsListFn);
        jest
          .spyOn(mockWatcher, 'subscribeToStream')
          .mockImplementation(mockDeploymentsListWatcherFn);
        jest.spyOn(mockWatcher, 'on').mockImplementation(mockOnDataFn);
      });

      it('should request all deployments from the cluster_client library and watch the events', async () => {
        const deployments = await mockResolvers.Query.k8sDeployments(
          null,
          {
            configuration,
          },
          { client },
        );

        expect(mockAllDeploymentsListFn).toHaveBeenCalled();
        expect(mockDeploymentsListWatcherFn).toHaveBeenCalled();

        expect(deployments).toEqual(k8sDeploymentsMock);
      });

      it('should update cache with the new data when received from the library', async () => {
        await mockResolvers.Query.k8sDeployments(
          null,
          { configuration, namespace: '' },
          { client },
        );

        expect(client.writeQuery).toHaveBeenCalledWith({
          query: k8sDashboardDeploymentsQuery,
          variables: { configuration, namespace: '' },
          data: { k8sDeployments: [] },
        });
      });
    });

    it('should not watch deployments from the cluster_client library when the deployments data is not present', async () => {
      jest.spyOn(AppsV1Api.prototype, 'listAppsV1DeploymentForAllNamespaces').mockImplementation(
        jest.fn().mockImplementation(() => {
          return Promise.resolve({
            items: [],
          });
        }),
      );

      await mockResolvers.Query.k8sDeployments(null, { configuration }, { client });

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

  describe('k8sStatefulSets', () => {
    const client = { writeQuery: jest.fn() };

    const mockWatcher = WatchApi.prototype;
    const mockStatefulSetsListWatcherFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWatcher);
    });

    const mockOnDataFn = jest.fn().mockImplementation((eventName, callback) => {
      if (eventName === 'data') {
        callback([]);
      }
    });

    const mockStatefulSetsListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        items: k8sStatefulSetsMock,
      });
    });

    const mockAllStatefulSetsListFn = jest.fn().mockImplementation(mockStatefulSetsListFn);

    describe('when the StatefulSets data is present', () => {
      beforeEach(() => {
        jest
          .spyOn(AppsV1Api.prototype, 'listAppsV1StatefulSetForAllNamespaces')
          .mockImplementation(mockAllStatefulSetsListFn);
        jest
          .spyOn(mockWatcher, 'subscribeToStream')
          .mockImplementation(mockStatefulSetsListWatcherFn);
        jest.spyOn(mockWatcher, 'on').mockImplementation(mockOnDataFn);
      });

      it('should request all StatefulSets from the cluster_client library and watch the events', async () => {
        const StatefulSets = await mockResolvers.Query.k8sStatefulSets(
          null,
          {
            configuration,
          },
          { client },
        );

        expect(mockAllStatefulSetsListFn).toHaveBeenCalled();
        expect(mockStatefulSetsListWatcherFn).toHaveBeenCalled();

        expect(StatefulSets).toEqual(k8sStatefulSetsMock);
      });

      it('should update cache with the new data when received from the library', async () => {
        await mockResolvers.Query.k8sStatefulSets(
          null,
          { configuration, namespace: '' },
          { client },
        );

        expect(client.writeQuery).toHaveBeenCalledWith({
          query: k8sDashboardStatefulSetsQuery,
          variables: { configuration, namespace: '' },
          data: { k8sStatefulSets: [] },
        });
      });
    });

    it('should not watch StatefulSets from the cluster_client library when the StatefulSets data is not present', async () => {
      jest.spyOn(AppsV1Api.prototype, 'listAppsV1StatefulSetForAllNamespaces').mockImplementation(
        jest.fn().mockImplementation(() => {
          return Promise.resolve({
            items: [],
          });
        }),
      );

      await mockResolvers.Query.k8sStatefulSets(null, { configuration }, { client });

      expect(mockStatefulSetsListWatcherFn).not.toHaveBeenCalled();
    });

    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(AppsV1Api.prototype, 'listAppsV1StatefulSetForAllNamespaces')
        .mockRejectedValue(new Error('API error'));

      await expect(
        mockResolvers.Query.k8sStatefulSets(null, { configuration }, { client }),
      ).rejects.toThrow('API error');
    });
  });

  describe('k8sReplicaSets', () => {
    const client = { writeQuery: jest.fn() };

    const mockWatcher = WatchApi.prototype;
    const mockReplicaSetsListWatcherFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWatcher);
    });

    const mockOnDataFn = jest.fn().mockImplementation((eventName, callback) => {
      if (eventName === 'data') {
        callback([]);
      }
    });

    const mockReplicaSetsListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        items: k8sReplicaSetsMock,
      });
    });

    const mockAllReplicaSetsListFn = jest.fn().mockImplementation(mockReplicaSetsListFn);

    describe('when the ReplicaSets data is present', () => {
      beforeEach(() => {
        jest
          .spyOn(AppsV1Api.prototype, 'listAppsV1ReplicaSetForAllNamespaces')
          .mockImplementation(mockAllReplicaSetsListFn);
        jest
          .spyOn(mockWatcher, 'subscribeToStream')
          .mockImplementation(mockReplicaSetsListWatcherFn);
        jest.spyOn(mockWatcher, 'on').mockImplementation(mockOnDataFn);
      });

      it('should request all ReplicaSets from the cluster_client library and watch the events', async () => {
        const ReplicaSets = await mockResolvers.Query.k8sReplicaSets(
          null,
          {
            configuration,
          },
          { client },
        );

        expect(mockAllReplicaSetsListFn).toHaveBeenCalled();
        expect(mockReplicaSetsListWatcherFn).toHaveBeenCalled();

        expect(ReplicaSets).toEqual(k8sReplicaSetsMock);
      });

      it('should update cache with the new data when received from the library', async () => {
        await mockResolvers.Query.k8sReplicaSets(
          null,
          { configuration, namespace: '' },
          { client },
        );

        expect(client.writeQuery).toHaveBeenCalledWith({
          query: k8sDashboardReplicaSetsQuery,
          variables: { configuration, namespace: '' },
          data: { k8sReplicaSets: [] },
        });
      });
    });

    it('should not watch ReplicaSets from the cluster_client library when the ReplicaSets data is not present', async () => {
      jest.spyOn(AppsV1Api.prototype, 'listAppsV1ReplicaSetForAllNamespaces').mockImplementation(
        jest.fn().mockImplementation(() => {
          return Promise.resolve({
            items: [],
          });
        }),
      );

      await mockResolvers.Query.k8sReplicaSets(null, { configuration }, { client });

      expect(mockReplicaSetsListWatcherFn).not.toHaveBeenCalled();
    });

    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(AppsV1Api.prototype, 'listAppsV1ReplicaSetForAllNamespaces')
        .mockRejectedValue(new Error('API error'));

      await expect(
        mockResolvers.Query.k8sReplicaSets(null, { configuration }, { client }),
      ).rejects.toThrow('API error');
    });
  });
});
