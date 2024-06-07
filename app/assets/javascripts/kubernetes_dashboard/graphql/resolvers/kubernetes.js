import { Configuration, CoreV1Api, AppsV1Api, BatchV1Api } from '@gitlab/cluster-client';

import {
  getK8sPods,
  handleClusterError,
  mapWorkloadItem,
  buildWatchPath,
  watchWorkloadItems,
} from '../helpers/resolver_helpers';
import k8sDashboardPodsQuery from '../queries/k8s_dashboard_pods.query.graphql';
import k8sDashboardDeploymentsQuery from '../queries/k8s_dashboard_deployments.query.graphql';
import k8sDashboardStatefulSetsQuery from '../queries/k8s_dashboard_stateful_sets.query.graphql';
import k8sDashboardReplicaSetsQuery from '../queries/k8s_dashboard_replica_sets.query.graphql';
import k8sDaemonSetsQuery from '../queries/k8s_dashboard_daemon_sets.query.graphql';
import k8sJobsQuery from '../queries/k8s_dashboard_jobs.query.graphql';
import k8sCronJobsQuery from '../queries/k8s_dashboard_cron_jobs.query.graphql';
import k8sServicesQuery from '../queries/k8s_dashboard_services.query.graphql';

export default {
  k8sDashboardPods(_, { configuration }, { client }) {
    const query = k8sDashboardPodsQuery;
    const enableWatch = true;
    const queryField = 'k8sDashboardPods';
    return getK8sPods({ client, query, configuration, enableWatch, queryField });
  },

  k8sDashboardDeployments(_, { configuration, namespace = '' }, { client }) {
    const config = new Configuration(configuration);

    const appsV1api = new AppsV1Api(config);
    const deploymentsApi = namespace
      ? appsV1api.listAppsV1NamespacedDeployment({ namespace })
      : appsV1api.listAppsV1DeploymentForAllNamespaces();
    return deploymentsApi
      .then((res) => {
        const watchPath = buildWatchPath({
          resource: 'deployments',
          api: 'apis/apps/v1',
          namespace,
        });
        watchWorkloadItems({
          client,
          query: k8sDashboardDeploymentsQuery,
          configuration,
          namespace,
          watchPath,
          queryField: 'k8sDeployments',
        });

        const data = res?.items || [];

        return data.map(mapWorkloadItem);
      })
      .catch(async (err) => {
        try {
          await handleClusterError(err);
        } catch (error) {
          throw new Error(error.message);
        }
      });
  },

  k8sStatefulSets(_, { configuration, namespace = '' }, { client }) {
    const config = new Configuration(configuration);

    const appsV1api = new AppsV1Api(config);
    const statefulSetsApi = namespace
      ? appsV1api.listAppsV1NamespacedStatefulSet({ namespace })
      : appsV1api.listAppsV1StatefulSetForAllNamespaces();
    return statefulSetsApi
      .then((res) => {
        const watchPath = buildWatchPath({
          resource: 'statefulsets',
          api: 'apis/apps/v1',
          namespace,
        });
        watchWorkloadItems({
          client,
          query: k8sDashboardStatefulSetsQuery,
          configuration,
          namespace,
          watchPath,
          queryField: 'k8sStatefulSets',
        });

        const data = res?.items || [];

        return data.map(mapWorkloadItem);
      })
      .catch(async (err) => {
        try {
          await handleClusterError(err);
        } catch (error) {
          throw new Error(error.message);
        }
      });
  },

  k8sReplicaSets(_, { configuration, namespace = '' }, { client }) {
    const config = new Configuration(configuration);

    const appsV1api = new AppsV1Api(config);
    const replicaSetsApi = namespace
      ? appsV1api.listAppsV1NamespacedReplicaSet({ namespace })
      : appsV1api.listAppsV1ReplicaSetForAllNamespaces();
    return replicaSetsApi
      .then((res) => {
        const watchPath = buildWatchPath({
          resource: 'replicasets',
          api: 'apis/apps/v1',
          namespace,
        });
        watchWorkloadItems({
          client,
          query: k8sDashboardReplicaSetsQuery,
          configuration,
          namespace,
          watchPath,
          queryField: 'k8sReplicaSets',
        });

        const data = res?.items || [];

        return data.map(mapWorkloadItem);
      })
      .catch(async (err) => {
        try {
          await handleClusterError(err);
        } catch (error) {
          throw new Error(error.message);
        }
      });
  },

  k8sDaemonSets(_, { configuration, namespace = '' }, { client }) {
    const config = new Configuration(configuration);

    const appsV1api = new AppsV1Api(config);
    const daemonSetsApi = namespace
      ? appsV1api.listAppsV1NamespacedDaemonSet({ namespace })
      : appsV1api.listAppsV1DaemonSetForAllNamespaces();
    return daemonSetsApi
      .then((res) => {
        const watchPath = buildWatchPath({
          resource: 'daemonsets',
          api: 'apis/apps/v1',
          namespace,
        });
        watchWorkloadItems({
          client,
          query: k8sDaemonSetsQuery,
          configuration,
          namespace,
          watchPath,
          queryField: 'k8sDaemonSets',
        });

        const data = res?.items || [];

        return data.map(mapWorkloadItem);
      })
      .catch(async (err) => {
        try {
          await handleClusterError(err);
        } catch (error) {
          throw new Error(error.message);
        }
      });
  },

  k8sJobs(_, { configuration, namespace = '' }, { client }) {
    const config = new Configuration(configuration);

    const batchV1api = new BatchV1Api(config);
    const jobsApi = namespace
      ? batchV1api.listBatchV1NamespacedJob({ namespace })
      : batchV1api.listBatchV1JobForAllNamespaces();
    return jobsApi
      .then((res) => {
        const watchPath = buildWatchPath({
          resource: 'jobs',
          api: 'apis/batch/v1',
          namespace,
        });
        watchWorkloadItems({
          client,
          query: k8sJobsQuery,
          configuration,
          namespace,
          watchPath,
          queryField: 'k8sJobs',
        });

        const data = res?.items || [];

        return data.map(mapWorkloadItem);
      })
      .catch(async (err) => {
        try {
          await handleClusterError(err);
        } catch (error) {
          throw new Error(error.message);
        }
      });
  },

  k8sCronJobs(_, { configuration, namespace = '' }, { client }) {
    const config = new Configuration(configuration);

    const batchV1api = new BatchV1Api(config);
    const cronJobsApi = namespace
      ? batchV1api.listBatchV1NamespacedCronJob({ namespace })
      : batchV1api.listBatchV1CronJobForAllNamespaces();
    return cronJobsApi
      .then((res) => {
        const watchPath = buildWatchPath({
          resource: 'cronjobs',
          api: 'apis/batch/v1',
          namespace,
        });
        watchWorkloadItems({
          client,
          query: k8sCronJobsQuery,
          configuration,
          namespace,
          watchPath,
          queryField: 'k8sCronJobs',
        });

        const data = res?.items || [];

        return data.map(mapWorkloadItem);
      })
      .catch(async (err) => {
        try {
          await handleClusterError(err);
        } catch (error) {
          throw new Error(error.message);
        }
      });
  },

  k8sDashboardServices(_, { configuration, namespace = '' }, { client }) {
    const config = new Configuration(configuration);

    const coreV1Api = new CoreV1Api(config);
    const servicesApi = namespace
      ? coreV1Api.listCoreV1NamespacedService({ namespace })
      : coreV1Api.listCoreV1ServiceForAllNamespaces();
    return servicesApi
      .then((res) => {
        const watchPath = buildWatchPath({
          resource: 'services',
          namespace,
        });
        watchWorkloadItems({
          client,
          query: k8sServicesQuery,
          configuration,
          namespace,
          watchPath,
          queryField: 'k8sDashboardServices',
        });

        const data = res?.items || [];

        return data.map(mapWorkloadItem);
      })
      .catch(async (err) => {
        try {
          await handleClusterError(err);
        } catch (error) {
          throw new Error(error.message);
        }
      });
  },
};
