import { Configuration, AppsV1Api } from '@gitlab/cluster-client';

import {
  getK8sPods,
  handleClusterError,
  mapWorkloadItem,
  mapSetItem,
  buildWatchPath,
  watchWorkloadItems,
} from '../helpers/resolver_helpers';
import k8sDashboardPodsQuery from '../queries/k8s_dashboard_pods.query.graphql';
import k8sDashboardDeploymentsQuery from '../queries/k8s_dashboard_deployments.query.graphql';
import k8sDashboardStatefulSetsQuery from '../queries/k8s_dashboard_stateful_sets.query.graphql';
import k8sDashboardReplicaSetsQuery from '../queries/k8s_dashboard_replica_sets.query.graphql';

export default {
  k8sPods(_, { configuration }, { client }) {
    const query = k8sDashboardPodsQuery;
    const enableWatch = true;
    return getK8sPods({ client, query, configuration, enableWatch });
  },

  k8sDeployments(_, { configuration, namespace = '' }, { client }) {
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
    const deploymentsApi = namespace
      ? appsV1api.listAppsV1NamespacedStatefulSet({ namespace })
      : appsV1api.listAppsV1StatefulSetForAllNamespaces();
    return deploymentsApi
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
          mapFn: mapSetItem,
        });

        const data = res?.items || [];

        return data.map(mapSetItem);
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
    const deploymentsApi = namespace
      ? appsV1api.listAppsV1NamespacedReplicaSet({ namespace })
      : appsV1api.listAppsV1ReplicaSetForAllNamespaces();
    return deploymentsApi
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
          mapFn: mapSetItem,
        });

        const data = res?.items || [];

        return data.map(mapSetItem);
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
