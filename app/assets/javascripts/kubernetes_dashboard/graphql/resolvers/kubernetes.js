import { Configuration, AppsV1Api } from '@gitlab/cluster-client';

import {
  getK8sPods,
  handleClusterError,
  mapWorkloadItem,
  buildWatchPath,
  watchWorkloadItems,
} from '../helpers/resolver_helpers';
import k8sDashboardPodsQuery from '../queries/k8s_dashboard_pods.query.graphql';
import k8sDashboardDeploymentsQuery from '../queries/k8s_dashboard_deployments.query.graphql';

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
};
