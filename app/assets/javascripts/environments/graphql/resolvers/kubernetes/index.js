import { CoreV1Api, Configuration } from '@gitlab/cluster-client';
import {
  getK8sPods,
  watchWorkloadItems,
  handleClusterError,
  buildWatchPath,
  mapWorkloadItem,
} from '~/kubernetes_dashboard/graphql/helpers/resolver_helpers';
import { humanizeClusterErrors } from '../../../helpers/k8s_integration_helper';
import k8sPodsQuery from '../../queries/k8s_pods.query.graphql';
import k8sServicesQuery from '../../queries/k8s_services.query.graphql';
import { k8sResourceType } from './constants';

const watchServices = ({ configuration, namespace, client }) => {
  const query = k8sServicesQuery;
  const watchPath = buildWatchPath({ resource: 'services', namespace });
  const queryField = k8sResourceType.k8sServices;
  watchWorkloadItems({ client, query, configuration, namespace, watchPath, queryField });
};

const watchPods = ({ configuration, namespace, client }) => {
  const query = k8sPodsQuery;
  const watchPath = buildWatchPath({ resource: 'pods', namespace });
  const queryField = k8sResourceType.k8sPods;
  watchWorkloadItems({ client, query, configuration, namespace, watchPath, queryField });
};

export const kubernetesMutations = {
  reconnectToCluster(_, { configuration, namespace, resourceType }, { client }) {
    const errors = [];
    try {
      if (resourceType === k8sResourceType.k8sServices) {
        watchServices({ configuration, namespace, client });
      }
      if (resourceType === k8sResourceType.k8sPods) {
        watchPods({ configuration, namespace, client });
      }
    } catch (error) {
      errors.push(error);
    }

    return errors;
  },
};

export const kubernetesQueries = {
  k8sPods(_, { configuration, namespace }, { client }) {
    const query = k8sPodsQuery;
    const enableWatch = gon.features?.k8sWatchApi;
    return getK8sPods({ client, query, configuration, namespace, enableWatch });
  },
  k8sServices(_, { configuration, namespace }, { client }) {
    const coreV1Api = new CoreV1Api(new Configuration(configuration));
    const servicesApi = namespace
      ? coreV1Api.listCoreV1NamespacedService({ namespace })
      : coreV1Api.listCoreV1ServiceForAllNamespaces();

    return servicesApi
      .then((res) => {
        const items = res?.items || [];

        if (gon.features?.k8sWatchApi) {
          watchServices({ configuration, namespace, client });
        }

        return items.map(mapWorkloadItem);
      })
      .catch(async (err) => {
        try {
          await handleClusterError(err);
        } catch (error) {
          throw new Error(error.message);
        }
      });
  },
  k8sNamespaces(_, { configuration }) {
    const coreV1Api = new CoreV1Api(new Configuration(configuration));
    const namespacesApi = coreV1Api.listCoreV1Namespace();

    return namespacesApi
      .then((res) => {
        return res?.items || [];
      })
      .catch(async (error) => {
        try {
          await handleClusterError(error);
        } catch (err) {
          throw new Error(humanizeClusterErrors(err.reason));
        }
      });
  },
};
