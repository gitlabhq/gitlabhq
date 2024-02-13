import { CoreV1Api, Configuration, WatchApi, EVENT_DATA } from '@gitlab/cluster-client';
import {
  getK8sPods,
  handleClusterError,
  buildWatchPath,
} from '~/kubernetes_dashboard/graphql/helpers/resolver_helpers';
import { humanizeClusterErrors } from '../../helpers/k8s_integration_helper';
import k8sPodsQuery from '../queries/k8s_pods.query.graphql';
import k8sServicesQuery from '../queries/k8s_services.query.graphql';

const mapServicesItems = (items) => {
  return items.map((item) => {
    const { type, clusterIP, externalIP, ports } = item.spec;
    return {
      metadata: item.metadata,
      spec: {
        type,
        clusterIP: clusterIP || '-',
        externalIP: externalIP || '-',
        ports,
      },
    };
  });
};

const watchServices = ({ configuration, namespace, client }) => {
  const path = buildWatchPath({ resource: 'services', namespace });
  const config = new Configuration(configuration);
  const watcherApi = new WatchApi(config);

  watcherApi
    .subscribeToStream(path, { watch: true })
    .then((watcher) => {
      let result = [];

      watcher.on(EVENT_DATA, (data) => {
        result = mapServicesItems(data);

        client.writeQuery({
          query: k8sServicesQuery,
          variables: { configuration, namespace },
          data: { k8sServices: result },
        });
      });
    })
    .catch((err) => {
      handleClusterError(err);
    });
};

export default {
  k8sPods(_, { configuration, namespace }, { client }) {
    const query = k8sPodsQuery;
    const enableWatch = gon.features?.k8sWatchApi;
    // TODO: Remove mapping function once the drawer with the pods details is added under the Kubernetes overview section
    const mapPodItem = (item) => item;
    return getK8sPods({ client, query, configuration, namespace, enableWatch, mapFn: mapPodItem });
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

        return mapServicesItems(items);
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
