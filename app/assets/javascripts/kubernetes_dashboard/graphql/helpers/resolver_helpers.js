import {
  CoreV1Api,
  Configuration,
  WatchApi,
  webSocketWatchManager,
  EVENT_DATA,
  EVENT_TIMEOUT,
  EVENT_ERROR,
} from '@gitlab/cluster-client';
import { connectionStatus } from '~/environments/graphql/resolvers/kubernetes/constants';
import { updateConnectionStatus } from '~/environments/graphql/resolvers/kubernetes/k8s_connection_status';
import { s__ } from '~/locale';

export const handleClusterError = async (err) => {
  if (!err.response) {
    throw err;
  }

  const contentType = err.response.headers.get('Content-Type');

  if (contentType !== 'application/json') {
    throw new Error(
      s__(
        'KubernetesDashboard|There was a problem fetching cluster information. Refresh the page and try again.',
      ),
    );
  }

  const errorData = await err.response.json();
  throw errorData;
};

export const buildWatchPath = ({ resource, api = 'api/v1', namespace = '' }) => {
  return namespace ? `/${api}/namespaces/${namespace}/${resource}` : `/${api}/${resource}`;
};

export const mapWorkloadItem = (item) => {
  const status = item.status || {};
  const spec = item.spec || {};
  const metadata = {
    ...item.metadata,
    annotations: item.metadata?.annotations || {},
    labels: item.metadata?.labels || {},
  };
  return { status, spec, metadata, __typename: 'LocalWorkloadItem' };
};

export const mapEventItem = ({
  lastTimestamp = '',
  eventTime = '',
  message,
  reason,
  source,
  type,
}) => ({ lastTimestamp, eventTime, message, reason, source, type });

export const subscribeToSocket = async ({ watchId, watchParams, configuration, cacheParams }) => {
  const { updateQueryCache, updateConnectionStatusFn } = cacheParams;

  try {
    const watcher = await webSocketWatchManager.initConnection({
      message: { watchId, watchParams },
      configuration,
    });

    const handleConnectionStatus = (status) => {
      if (updateConnectionStatusFn) {
        updateConnectionStatusFn(status);
      }
    };

    watcher.on(EVENT_DATA, watchId, (data) => {
      updateQueryCache(data);
      handleConnectionStatus(connectionStatus.connected);
    });

    watcher.on(EVENT_ERROR, watchId, () => {
      handleConnectionStatus(connectionStatus.disconnected);
    });
  } catch (err) {
    throw new Error(s__('KubernetesDashboard|Failed to establish WebSocket connection'));
  }
};

export const watchWorkloadItems = async ({
  client,
  query,
  configuration,
  namespace,
  watchPath,
  queryField,
  watchParams,
}) => {
  const config = new Configuration(configuration);
  const watcherApi = new WatchApi(config);

  const updateStatus = (status) =>
    updateConnectionStatus(client, {
      configuration,
      namespace,
      resourceType: queryField,
      status,
    });

  const updateQueryCache = (data) => {
    const result = data.map(mapWorkloadItem);
    client.writeQuery({
      query,
      variables: { configuration, namespace },
      data: { [queryField]: result },
    });
  };

  const watchFunction = async () => {
    try {
      const watcher = await watcherApi.subscribeToStream(watchPath, { watch: true });

      watcher.on(EVENT_DATA, (data) => {
        updateQueryCache(data);
        updateStatus(connectionStatus.connected);
      });

      watcher.on(EVENT_TIMEOUT, () => {
        updateStatus(connectionStatus.disconnected);
      });

      watcher.on(EVENT_ERROR, () => {
        updateStatus(connectionStatus.disconnected);
      });
    } catch (err) {
      await handleClusterError(err);
    }
  };

  updateStatus(connectionStatus.connecting);

  if (gon?.features?.useWebsocketForK8sWatch && watchParams) {
    const watchId = namespace ? `${queryField}-n-${namespace}` : `${queryField}-all-namespaces`;
    const cacheParams = {
      updateQueryCache,
      updateConnectionStatusFn: updateStatus,
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

export const getK8sPods = ({
  client,
  query,
  configuration,
  namespace = '',
  mapFn = mapWorkloadItem,
  queryField = 'k8sPods',
}) => {
  const config = new Configuration(configuration);

  const coreV1Api = new CoreV1Api(config);
  const podsApi = namespace
    ? coreV1Api.listCoreV1NamespacedPod({ namespace })
    : coreV1Api.listCoreV1PodForAllNamespaces();

  return podsApi
    .then((res) => {
      const watchPath = buildWatchPath({ resource: 'pods', namespace });
      const watchParams = {
        version: 'v1',
        resource: 'pods',
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

      const data = res?.items || [];
      return data.map(mapFn);
    })
    .catch(async (err) => {
      try {
        await handleClusterError(err);
      } catch (error) {
        throw new Error(error.message);
      }
    });
};
