import {
  CoreV1Api,
  WatchApi,
  AppsV1Api,
  BatchV1Api,
  WebSocketWatchManager,
} from '@gitlab/cluster-client';
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

describe('~/frontend/kubernetes_dashboard/graphql/resolvers', () => {
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

  const setupK8sWebSocketMocks = () => {
    const mockWebsocketManager = WebSocketWatchManager.prototype;
    const mockInitConnectionFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWebsocketManager);
    });

    const eventCallbacks = {};
    const mockOnFn = jest.fn().mockImplementation((eventName, watchId, callback) => {
      if (typeof callback === 'function') {
        eventCallbacks[eventName] = callback;
      }
    });

    jest.spyOn(mockWebsocketManager, 'initConnection').mockImplementation(mockInitConnectionFn);
    jest.spyOn(mockWebsocketManager, 'on').mockImplementation(mockOnFn);

    return {
      mockInitConnectionFn,
      triggerWebSocketEvent: (eventName, data) => {
        if (eventCallbacks[eventName]) {
          eventCallbacks[eventName](data);
        }
      },
    };
  };

  const resourceTestCases = [
    {
      name: 'k8sDashboardPods',
      mockData: k8sPodsMock,
      query: k8sDashboardPodsQuery,
      apiMethod: 'listCoreV1PodForAllNamespaces',
      apiClass: CoreV1Api,
      queryField: 'k8sDashboardPods',
      watchId: 'k8sDashboardPods-all-namespaces',
      watchParams: {
        namespace: '',
        resource: 'pods',
        version: 'v1',
      },
    },
    {
      name: 'k8sDashboardDeployments',
      mockData: k8sDeploymentsMock,
      query: k8sDashboardDeploymentsQuery,
      apiMethod: 'listAppsV1DeploymentForAllNamespaces',
      apiClass: AppsV1Api,
      queryField: 'k8sDeployments',
      watchId: 'k8sDeployments-all-namespaces',
      watchParams: {
        group: 'apps',
        namespace: '',
        resource: 'deployments',
        version: 'v1',
      },
    },
    {
      name: 'k8sStatefulSets',
      mockData: k8sStatefulSetsMock,
      query: k8sDashboardStatefulSetsQuery,
      apiMethod: 'listAppsV1StatefulSetForAllNamespaces',
      apiClass: AppsV1Api,
      queryField: 'k8sStatefulSets',
      watchId: 'k8sStatefulSets-all-namespaces',
      watchParams: {
        group: 'apps',
        namespace: '',
        resource: 'statefulsets',
        version: 'v1',
      },
    },
    {
      name: 'k8sReplicaSets',
      mockData: k8sReplicaSetsMock,
      query: k8sDashboardReplicaSetsQuery,
      apiMethod: 'listAppsV1ReplicaSetForAllNamespaces',
      apiClass: AppsV1Api,
      queryField: 'k8sReplicaSets',
      watchId: 'k8sReplicaSets-all-namespaces',
      watchParams: {
        group: 'apps',
        namespace: '',
        resource: 'replicasets',
        version: 'v1',
      },
    },
    {
      name: 'k8sDaemonSets',
      mockData: k8sDaemonSetsMock,
      query: k8sDashboardDaemonSetsQuery,
      apiMethod: 'listAppsV1DaemonSetForAllNamespaces',
      apiClass: AppsV1Api,
      queryField: 'k8sDaemonSets',
      watchId: 'k8sDaemonSets-all-namespaces',
      watchParams: {
        group: 'apps',
        namespace: '',
        resource: 'daemonsets',
        version: 'v1',
      },
    },
    {
      name: 'k8sJobs',
      mockData: k8sJobsMock,
      query: k8sDashboardJobsQuery,
      apiMethod: 'listBatchV1JobForAllNamespaces',
      apiClass: BatchV1Api,
      queryField: 'k8sJobs',
      watchId: 'k8sJobs-all-namespaces',
      watchParams: {
        group: 'batch',
        namespace: '',
        resource: 'jobs',
        version: 'v1',
      },
    },
    {
      name: 'k8sCronJobs',
      mockData: k8sCronJobsMock,
      query: k8sDashboardCronJobsQuery,
      apiMethod: 'listBatchV1CronJobForAllNamespaces',
      apiClass: BatchV1Api,
      queryField: 'k8sCronJobs',
      watchId: 'k8sCronJobs-all-namespaces',
      watchParams: {
        group: 'batch',
        namespace: '',
        resource: 'cronjobs',
        version: 'v1',
      },
    },
    {
      name: 'k8sDashboardServices',
      mockData: k8sServicesMock,
      query: k8sDashboardServicesQuery,
      apiMethod: 'listCoreV1ServiceForAllNamespaces',
      apiClass: CoreV1Api,
      queryField: 'k8sDashboardServices',
      watchId: 'k8sDashboardServices-all-namespaces',
      watchParams: {
        namespace: '',
        resource: 'services',
        version: 'v1',
      },
    },
  ];

  resourceTestCases.forEach(
    ({ name, mockData, query, apiMethod, apiClass, queryField, watchId, watchParams }) => {
      describe(name, () => {
        const mockWatcher = WatchApi.prototype;
        const mockListWatcherFn = jest.fn().mockImplementation(() => {
          return Promise.resolve(mockWatcher);
        });

        const mockOnDataFn = jest.fn().mockImplementation((eventName, callback) => {
          if (eventName === 'data') {
            callback([]);
          }
        });

        const mockListFn = jest.fn().mockImplementation(() => {
          return Promise.resolve({ items: mockData });
        });

        describe('when data is present', () => {
          let mockInitConnectionFn;
          let triggerWebSocketEvent;

          beforeEach(() => {
            ({ mockInitConnectionFn, triggerWebSocketEvent } = setupK8sWebSocketMocks());
            jest.spyOn(apiClass.prototype, apiMethod).mockImplementation(mockListFn);
            jest.spyOn(mockWatcher, 'subscribeToStream').mockImplementation(mockListWatcherFn);
            jest.spyOn(mockWatcher, 'on').mockImplementation(mockOnDataFn);
          });

          it('calls websocket API', async () => {
            await mockResolvers.Query[name](null, { configuration }, { client });

            expect(mockInitConnectionFn).toHaveBeenCalledWith({
              message: {
                watchId,
                watchParams,
              },
            });
          });

          it("doesn't call watch API when using websocket", async () => {
            await mockResolvers.Query[name](null, { configuration }, { client });

            expect(mockListFn).toHaveBeenCalled();
            expect(mockListWatcherFn).not.toHaveBeenCalled();
          });

          it('returns data when received from the library', async () => {
            const result = await mockResolvers.Query[name](null, { configuration }, { client });
            expect(result).toEqual(mockData);
          });

          it('updates cache with the new data when received from websocket', async () => {
            await mockResolvers.Query[name](null, { configuration, namespace: '' }, { client });

            triggerWebSocketEvent('data', []);

            expect(client.writeQuery).toHaveBeenCalledWith({
              query,
              variables: { configuration, namespace: '' },
              data: { [queryField]: [] },
            });
          });

          describe('when websocket connection fails', () => {
            beforeEach(() => {
              jest
                .spyOn(WebSocketWatchManager.prototype, 'initConnection')
                .mockImplementation(() => {
                  throw new Error('WebSocket connection failed');
                });
            });

            it('falls back to watch API when websocket connection fails', async () => {
              await mockResolvers.Query[name](null, { configuration }, { client });
              expect(mockListWatcherFn).toHaveBeenCalled();
            });
          });
        });

        it('does not watch when data is not present', async () => {
          jest.spyOn(apiClass.prototype, apiMethod).mockImplementation(() => {
            return Promise.resolve({ items: [] });
          });

          await mockResolvers.Query[name](null, { configuration }, { client });
          expect(mockListWatcherFn).not.toHaveBeenCalled();
        });

        it('throws an error if the API call fails', async () => {
          jest.spyOn(apiClass.prototype, apiMethod).mockRejectedValue(new Error('API error'));

          await expect(
            mockResolvers.Query[name](null, { configuration }, { client }),
          ).rejects.toThrow('API error');
        });
      });
    },
  );

  describe('k8sDashboardPods error handling', () => {
    it('returns a generic error message if the error response is not of JSON type', async () => {
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
});
