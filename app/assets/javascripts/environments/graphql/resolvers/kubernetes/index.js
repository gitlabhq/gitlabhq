import { CoreV1Api, AppsV1Api, Configuration, WatchApi, EVENT_DATA } from '@gitlab/cluster-client';
import { __ } from '~/locale';
import {
  getK8sPods,
  watchWorkloadItems,
  handleClusterError,
  buildWatchPath,
  mapWorkloadItem,
  mapEventItem,
  subscribeToSocket,
} from '~/kubernetes_dashboard/graphql/helpers/resolver_helpers';
import {
  watchFluxKustomization,
  watchFluxHelmRelease,
} from '~/environments/graphql/resolvers/flux';
import {
  humanizeClusterErrors,
  buildKubernetesErrors,
} from '~/environments/helpers/k8s_integration_helper';
import k8sPodsQuery from '../../queries/k8s_pods.query.graphql';
import k8sServicesQuery from '../../queries/k8s_services.query.graphql';
import k8sDeploymentsQuery from '../../queries/k8s_deployments.query.graphql';
import k8sEventsQuery from '../../queries/k8s_events.query.graphql';
import { k8sResourceType } from './constants';
import { k8sLogs, k8sPodLogsWatcher, abortK8sPodLogsStream } from './k8s_logs';

const watchServices = ({ configuration, namespace, client }) => {
  const query = k8sServicesQuery;
  const queryField = k8sResourceType.k8sServices;

  const watchPath = buildWatchPath({ resource: 'services', namespace });
  const watchParams = {
    version: 'v1',
    resource: 'services',
    namespace,
  };

  watchWorkloadItems({
    client,
    query,
    configuration,
    namespace,
    watchPath,
    queryField,
    watchParams,
  });
};

const watchPods = ({ configuration, namespace, client }) => {
  const query = k8sPodsQuery;
  const watchPath = buildWatchPath({ resource: 'pods', namespace });
  const queryField = k8sResourceType.k8sPods;

  watchWorkloadItems({
    client,
    query,
    configuration,
    namespace,
    watchPath,
    queryField,
  });
};

const watchDeployments = ({ configuration, namespace, client }) => {
  const query = k8sDeploymentsQuery;
  const watchPath = buildWatchPath({ resource: 'deployments', api: 'apis/apps/v1', namespace });
  const queryField = k8sResourceType.k8sDeployments;
  const watchParams = {
    group: 'apps',
    version: 'v1',
    resource: 'deployments',
    namespace,
  };

  watchWorkloadItems({
    client,
    query,
    configuration,
    namespace,
    watchPath,
    queryField,
    watchParams,
  });
};

export const watchEvents = async ({
  client,
  configuration,
  namespace,
  involvedObjectName,
  query,
}) => {
  const fieldSelector = `involvedObject.name=${involvedObjectName}`;
  const queryField = 'k8sEvents';

  const updateQueryCache = (data) => {
    const result = data.map(mapEventItem);
    client.writeQuery({
      query,
      variables: { configuration, namespace, involvedObjectName },
      data: { [queryField]: result },
    });
  };

  const watchFunction = async () => {
    try {
      const config = new Configuration(configuration);
      const watcherApi = new WatchApi(config);
      const watchPath = buildWatchPath({ resource: 'events', namespace });
      const watcher = await watcherApi.subscribeToStream(watchPath, { fieldSelector, watch: true });

      watcher.on(EVENT_DATA, updateQueryCache);
    } catch (err) {
      await handleClusterError(err);
    }
  };

  if (gon?.features?.useWebsocketForK8sWatch) {
    const watchId = `events-io-${involvedObjectName}`;
    const watchParams = { version: 'v1', resource: 'events', fieldSelector, namespace };
    const cacheParams = {
      updateQueryCache,
    };

    try {
      await subscribeToSocket({ watchId, watchParams, configuration, cacheParams });
    } catch {
      await watchFunction();
    }
  } else {
    await watchFunction();
  }
};

const handleKubernetesMutationError = async (err) => {
  const defaultError = __('Something went wrong. Please try again.');
  if (!err.response) {
    return err.message || defaultError;
  }

  const errorData = await err.response.json();
  if (errorData.message) {
    return errorData.message;
  }
  return defaultError;
};

export const kubernetesMutations = {
  reconnectToCluster(_, { configuration, namespace, resourceTypeParam }, { client }) {
    const errors = [];
    try {
      const { resourceType, connectionParams } = resourceTypeParam;
      if (resourceType === k8sResourceType.k8sServices) {
        watchServices({ configuration, namespace, client });
      }
      if (resourceType === k8sResourceType.k8sPods) {
        watchPods({ configuration, namespace, client });
      }
      if (resourceType === k8sResourceType.fluxKustomizations) {
        const { fluxResourcePath } = connectionParams;
        watchFluxKustomization({ configuration, client, fluxResourcePath });
      }
      if (resourceType === k8sResourceType.fluxHelmReleases) {
        const { fluxResourcePath } = connectionParams;
        watchFluxHelmRelease({ configuration, client, fluxResourcePath });
      }
    } catch (error) {
      errors.push(error);
    }

    return { errors };
  },

  deleteKubernetesPod(_, { configuration, namespace, podName }) {
    const config = new Configuration(configuration);
    const coreV1Api = new CoreV1Api(config);

    return coreV1Api
      .deleteCoreV1NamespacedPod({ namespace, name: podName })
      .then(() => {
        return buildKubernetesErrors();
      })
      .catch(async (err) => {
        const error = await handleKubernetesMutationError(err);
        return buildKubernetesErrors([error]);
      });
  },
  abortK8sPodLogsStream,
};

export const kubernetesQueries = {
  k8sPods(_, { configuration, namespace }, { client }) {
    const query = k8sPodsQuery;

    return getK8sPods({ client, query, configuration, namespace });
  },
  k8sServices(_, { configuration, namespace }, { client }) {
    const coreV1Api = new CoreV1Api(new Configuration(configuration));
    const servicesApi = namespace
      ? coreV1Api.listCoreV1NamespacedService({ namespace })
      : coreV1Api.listCoreV1ServiceForAllNamespaces();

    return servicesApi
      .then((res) => {
        const items = res?.items || [];

        watchServices({ configuration, namespace, client });

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
  k8sDeployments(_, { configuration, namespace }, { client }) {
    const appsV1Api = new AppsV1Api(new Configuration(configuration));
    const deploymentsApi = namespace
      ? appsV1Api.listAppsV1NamespacedDeployment({ namespace })
      : appsV1Api.listAppsV1DeploymentForAllNamespaces();

    return deploymentsApi
      .then((res) => {
        const items = res?.items || [];

        watchDeployments({ configuration, namespace, client });

        return items.map((item) => {
          return { metadata: item.metadata, status: item.status || {} };
        });
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
  k8sEvents(_, { configuration, involvedObjectName, namespace }, { client }) {
    const fieldSelector = `involvedObject.name=${involvedObjectName}`;
    const config = new Configuration(configuration);

    const coreV1Api = new CoreV1Api(config);
    const eventsApi = coreV1Api.listCoreV1NamespacedEvent({ namespace, fieldSelector });
    return eventsApi
      .then((res) => {
        const data = res.items?.map(mapEventItem) ?? [];

        watchEvents({
          client,
          configuration,
          namespace,
          involvedObjectName,
          query: k8sEventsQuery,
        });

        return data;
      })
      .catch(async (err) => {
        try {
          await handleClusterError(err);
        } catch (error) {
          throw new Error(error.message);
        }
      });
  },
  k8sLogs,
  k8sPodLogsWatcher,
};
