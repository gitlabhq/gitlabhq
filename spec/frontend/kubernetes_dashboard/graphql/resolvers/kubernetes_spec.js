import { CoreV1Api, WatchApi, AppsV1Api, BatchV1Api } from '@gitlab/cluster-client';
import { resolvers } from '~/kubernetes_dashboard/graphql/resolvers';
import k8sDashboardPodsQuery from '~/kubernetes_dashboard/graphql/queries/k8s_dashboard_pods.query.graphql';
import k8sDashboardDeploymentsQuery from '~/kubernetes_dashboard/graphql/queries/k8s_dashboard_deployments.query.graphql';
import k8sDashboardStatefulSetsQuery from '~/kubernetes_dashboard/graphql/queries/k8s_dashboard_stateful_sets.query.graphql';
import k8sDashboardReplicaSetsQuery from '~/kubernetes_dashboard/graphql/queries/k8s_dashboard_replica_sets.query.graphql';
import k8sDashboardDaemonSetsQuery from '~/kubernetes_dashboard/graphql/queries/k8s_dashboard_daemon_sets.query.graphql';
import k8sDashboardJobsQuery from '~/kubernetes_dashboard/graphql/queries/k8s_dashboard_jobs.query.graphql';
import k8sDashboardCronJobsQuery from '~/kubernetes_dashboard/graphql/queries/k8s_dashboard_cron_jobs.query.graphql';
import k8sDashboardServicesQuery from '~/kubernetes_dashboard/graphql/queries/k8s_dashboard_services.query.graphql';
import {
  k8sPodsMock,
  k8sDeploymentsMock,
  k8sStatefulSetsMock,
  k8sReplicaSetsMock,
  k8sDaemonSetsMock,
  k8sJobsMock,
  k8sCronJobsMock,
  k8sServicesMock,
} from '../mock_data';

describe('~/frontend/environments/graphql/resolvers', () => {
  let mockResolvers;

  const configuration = {
    basePath: 'kas-proxy/',
    baseOptions: {
      headers: { 'GitLab-Agent-Id': '1' },
    },
  };

  const client = { writeQuery: jest.fn(), readQuery: jest.fn() };

  beforeEach(() => {
    mockResolvers = resolvers;
  });

  describe('k8sDashboardPods', () => {
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
        const pods = await mockResolvers.Query.k8sDashboardPods(
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
        await mockResolvers.Query.k8sDashboardPods(
          null,
          { configuration, namespace: '' },
          { client },
        );

        expect(client.writeQuery).toHaveBeenCalledWith({
          query: k8sDashboardPodsQuery,
          variables: { configuration, namespace: '' },
          data: { k8sDashboardPods: [] },
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

      await mockResolvers.Query.k8sDashboardPods(null, { configuration }, { client });

      expect(mockPodsListWatcherFn).not.toHaveBeenCalled();
    });

    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(CoreV1Api.prototype, 'listCoreV1PodForAllNamespaces')
        .mockRejectedValue(new Error('API error'));

      await expect(
        mockResolvers.Query.k8sDashboardPods(null, { configuration }, { client }),
      ).rejects.toThrow('API error');
    });

    it('should return a generic error message if the error response is not of JSON type', async () => {
      jest.spyOn(CoreV1Api.prototype, 'listCoreV1PodForAllNamespaces').mockRejectedValue({
        response: {
          headers: new Headers({ 'Content-Type': 'application/pdf' }),
        },
      });

      await expect(
        mockResolvers.Query.k8sDashboardPods(null, { configuration }, { client }),
      ).rejects.toThrow(
        'There was a problem fetching cluster information. Refresh the page and try again.',
      );
    });
  });

  describe('k8sDashboardDeployments', () => {
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
        const deployments = await mockResolvers.Query.k8sDashboardDeployments(
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
        await mockResolvers.Query.k8sDashboardDeployments(
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

      await mockResolvers.Query.k8sDashboardDeployments(null, { configuration }, { client });

      expect(mockDeploymentsListWatcherFn).not.toHaveBeenCalled();
    });

    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(AppsV1Api.prototype, 'listAppsV1DeploymentForAllNamespaces')
        .mockRejectedValue(new Error('API error'));

      await expect(
        mockResolvers.Query.k8sDashboardDeployments(null, { configuration }, { client }),
      ).rejects.toThrow('API error');
    });
  });

  describe('k8sStatefulSets', () => {
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

  describe('k8sDaemonSets', () => {
    const mockWatcher = WatchApi.prototype;
    const mockDaemonSetsListWatcherFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWatcher);
    });

    const mockOnDataFn = jest.fn().mockImplementation((eventName, callback) => {
      if (eventName === 'data') {
        callback([]);
      }
    });

    const mockDaemonSetsListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        items: k8sDaemonSetsMock,
      });
    });

    const mockAllDaemonSetsListFn = jest.fn().mockImplementation(mockDaemonSetsListFn);

    describe('when the DaemonSets data is present', () => {
      beforeEach(() => {
        jest
          .spyOn(AppsV1Api.prototype, 'listAppsV1DaemonSetForAllNamespaces')
          .mockImplementation(mockAllDaemonSetsListFn);
        jest
          .spyOn(mockWatcher, 'subscribeToStream')
          .mockImplementation(mockDaemonSetsListWatcherFn);
        jest.spyOn(mockWatcher, 'on').mockImplementation(mockOnDataFn);
      });

      it('should request all DaemonSets from the cluster_client library and watch the events', async () => {
        const DaemonSets = await mockResolvers.Query.k8sDaemonSets(
          null,
          {
            configuration,
          },
          { client },
        );

        expect(mockAllDaemonSetsListFn).toHaveBeenCalled();
        expect(mockDaemonSetsListWatcherFn).toHaveBeenCalled();

        expect(DaemonSets).toEqual(k8sDaemonSetsMock);
      });

      it('should update cache with the new data when received from the library', async () => {
        await mockResolvers.Query.k8sDaemonSets(null, { configuration, namespace: '' }, { client });

        expect(client.writeQuery).toHaveBeenCalledWith({
          query: k8sDashboardDaemonSetsQuery,
          variables: { configuration, namespace: '' },
          data: { k8sDaemonSets: [] },
        });
      });
    });

    it('should not watch DaemonSets from the cluster_client library when the DaemonSets data is not present', async () => {
      jest.spyOn(AppsV1Api.prototype, 'listAppsV1DaemonSetForAllNamespaces').mockImplementation(
        jest.fn().mockImplementation(() => {
          return Promise.resolve({
            items: [],
          });
        }),
      );

      await mockResolvers.Query.k8sDaemonSets(null, { configuration }, { client });

      expect(mockDaemonSetsListWatcherFn).not.toHaveBeenCalled();
    });

    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(AppsV1Api.prototype, 'listAppsV1DaemonSetForAllNamespaces')
        .mockRejectedValue(new Error('API error'));

      await expect(
        mockResolvers.Query.k8sDaemonSets(null, { configuration }, { client }),
      ).rejects.toThrow('API error');
    });
  });

  describe('k8sJobs', () => {
    const mockWatcher = WatchApi.prototype;
    const mockJobsListWatcherFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWatcher);
    });

    const mockOnDataFn = jest.fn().mockImplementation((eventName, callback) => {
      if (eventName === 'data') {
        callback([]);
      }
    });

    const mockJobsListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        items: k8sJobsMock,
      });
    });

    const mockAllJobsListFn = jest.fn().mockImplementation(mockJobsListFn);

    describe('when the Jobs data is present', () => {
      beforeEach(() => {
        jest
          .spyOn(BatchV1Api.prototype, 'listBatchV1JobForAllNamespaces')
          .mockImplementation(mockAllJobsListFn);
        jest.spyOn(mockWatcher, 'subscribeToStream').mockImplementation(mockJobsListWatcherFn);
        jest.spyOn(mockWatcher, 'on').mockImplementation(mockOnDataFn);
      });

      it('should request all Jobs from the cluster_client library and watch the events', async () => {
        const Jobs = await mockResolvers.Query.k8sJobs(
          null,
          {
            configuration,
          },
          { client },
        );

        expect(mockAllJobsListFn).toHaveBeenCalled();
        expect(mockJobsListWatcherFn).toHaveBeenCalled();

        expect(Jobs).toEqual(k8sJobsMock);
      });

      it('should update cache with the new data when received from the library', async () => {
        await mockResolvers.Query.k8sJobs(null, { configuration, namespace: '' }, { client });

        expect(client.writeQuery).toHaveBeenCalledWith({
          query: k8sDashboardJobsQuery,
          variables: { configuration, namespace: '' },
          data: { k8sJobs: [] },
        });
      });
    });

    it('should not watch Jobs from the cluster_client library when the Jobs data is not present', async () => {
      jest.spyOn(BatchV1Api.prototype, 'listBatchV1JobForAllNamespaces').mockImplementation(
        jest.fn().mockImplementation(() => {
          return Promise.resolve({
            items: [],
          });
        }),
      );

      await mockResolvers.Query.k8sJobs(null, { configuration }, { client });

      expect(mockJobsListWatcherFn).not.toHaveBeenCalled();
    });

    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(BatchV1Api.prototype, 'listBatchV1JobForAllNamespaces')
        .mockRejectedValue(new Error('API error'));

      await expect(
        mockResolvers.Query.k8sJobs(null, { configuration }, { client }),
      ).rejects.toThrow('API error');
    });
  });

  describe('k8sCronJobs', () => {
    const mockWatcher = WatchApi.prototype;
    const mockCronJobsListWatcherFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWatcher);
    });

    const mockOnDataFn = jest.fn().mockImplementation((eventName, callback) => {
      if (eventName === 'data') {
        callback([]);
      }
    });

    const mockCronJobsListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        items: k8sCronJobsMock,
      });
    });

    const mockAllCronJobsListFn = jest.fn().mockImplementation(mockCronJobsListFn);

    describe('when the CronJobs data is present', () => {
      beforeEach(() => {
        jest
          .spyOn(BatchV1Api.prototype, 'listBatchV1CronJobForAllNamespaces')
          .mockImplementation(mockAllCronJobsListFn);
        jest.spyOn(mockWatcher, 'subscribeToStream').mockImplementation(mockCronJobsListWatcherFn);
        jest.spyOn(mockWatcher, 'on').mockImplementation(mockOnDataFn);
      });

      it('should request all CronJobs from the cluster_client library and watch the events', async () => {
        const CronJobs = await mockResolvers.Query.k8sCronJobs(
          null,
          {
            configuration,
          },
          { client },
        );

        expect(mockAllCronJobsListFn).toHaveBeenCalled();
        expect(mockCronJobsListWatcherFn).toHaveBeenCalled();

        expect(CronJobs).toEqual(k8sCronJobsMock);
      });

      it('should update cache with the new data when received from the library', async () => {
        await mockResolvers.Query.k8sCronJobs(null, { configuration, namespace: '' }, { client });

        expect(client.writeQuery).toHaveBeenCalledWith({
          query: k8sDashboardCronJobsQuery,
          variables: { configuration, namespace: '' },
          data: { k8sCronJobs: [] },
        });
      });
    });

    it('should not watch CronJobs from the cluster_client library when the CronJobs data is not present', async () => {
      jest.spyOn(BatchV1Api.prototype, 'listBatchV1CronJobForAllNamespaces').mockImplementation(
        jest.fn().mockImplementation(() => {
          return Promise.resolve({
            items: [],
          });
        }),
      );

      await mockResolvers.Query.k8sCronJobs(null, { configuration }, { client });

      expect(mockCronJobsListWatcherFn).not.toHaveBeenCalled();
    });

    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(BatchV1Api.prototype, 'listBatchV1CronJobForAllNamespaces')
        .mockRejectedValue(new Error('API error'));

      await expect(
        mockResolvers.Query.k8sCronJobs(null, { configuration }, { client }),
      ).rejects.toThrow('API error');
    });
  });

  describe('k8sDashboardServices', () => {
    const mockWatcher = WatchApi.prototype;
    const mockServicesListWatcherFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWatcher);
    });

    const mockOnDataFn = jest.fn().mockImplementation((eventName, callback) => {
      if (eventName === 'data') {
        callback([]);
      }
    });

    const mockServicesListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        items: k8sServicesMock,
      });
    });

    const mockAllServicesListFn = jest.fn().mockImplementation(mockServicesListFn);

    describe('when the Services data is present', () => {
      beforeEach(() => {
        jest
          .spyOn(CoreV1Api.prototype, 'listCoreV1ServiceForAllNamespaces')
          .mockImplementation(mockAllServicesListFn);
        jest.spyOn(mockWatcher, 'subscribeToStream').mockImplementation(mockServicesListWatcherFn);
        jest.spyOn(mockWatcher, 'on').mockImplementation(mockOnDataFn);
      });

      it('should request all Services from the cluster_client library and watch the events', async () => {
        const Services = await mockResolvers.Query.k8sDashboardServices(
          null,
          {
            configuration,
          },
          { client },
        );

        expect(mockAllServicesListFn).toHaveBeenCalled();
        expect(mockServicesListWatcherFn).toHaveBeenCalled();

        expect(Services).toEqual(k8sServicesMock);
      });

      it('should update cache with the new data when received from the library', async () => {
        await mockResolvers.Query.k8sDashboardServices(
          null,
          { configuration, namespace: '' },
          { client },
        );

        expect(client.writeQuery).toHaveBeenCalledWith({
          query: k8sDashboardServicesQuery,
          variables: { configuration, namespace: '' },
          data: { k8sDashboardServices: [] },
        });
      });
    });

    it('should not watch Services from the cluster_client library when the Services data is not present', async () => {
      jest.spyOn(CoreV1Api.prototype, 'listCoreV1ServiceForAllNamespaces').mockImplementation(
        jest.fn().mockImplementation(() => {
          return Promise.resolve({
            items: [],
          });
        }),
      );

      await mockResolvers.Query.k8sDashboardServices(null, { configuration }, { client });

      expect(mockServicesListWatcherFn).not.toHaveBeenCalled();
    });

    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(CoreV1Api.prototype, 'listCoreV1ServiceForAllNamespaces')
        .mockRejectedValue(new Error('API error'));

      await expect(
        mockResolvers.Query.k8sDashboardServices(null, { configuration }, { client }),
      ).rejects.toThrow('API error');
    });
  });
});
