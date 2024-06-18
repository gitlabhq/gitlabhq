import {
  CoreV1Api,
  Configuration,
  WatchApi,
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

export const watchWorkloadItems = ({
  client,
  query,
  configuration,
  namespace,
  watchPath,
  queryField,
}) => {
  const config = new Configuration(configuration);
  const watcherApi = new WatchApi(config);

  updateConnectionStatus(client, {
    configuration,
    namespace,
    resourceType: queryField,
    status: connectionStatus.connecting,
  });

  watcherApi
    .subscribeToStream(watchPath, { watch: true })
    .then((watcher) => {
      let result = [];

      watcher.on(EVENT_DATA, (data) => {
        result = data.map(mapWorkloadItem);
        client.writeQuery({
          query,
          variables: { configuration, namespace },
          data: { [queryField]: result },
        });
        updateConnectionStatus(client, {
          configuration,
          namespace,
          resourceType: queryField,
          status: connectionStatus.connected,
        });
      });

      watcher.on(EVENT_TIMEOUT, () => {
        result = [];

        updateConnectionStatus(client, {
          configuration,
          namespace,
          resourceType: queryField,
          status: connectionStatus.disconnected,
        });
      });

      watcher.on(EVENT_ERROR, () => {
        result = [];
        updateConnectionStatus(client, {
          configuration,
          namespace,
          resourceType: queryField,
          status: connectionStatus.disconnected,
        });
      });
    })
    .catch((err) => {
      handleClusterError(err);
    });
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
      watchWorkloadItems({
        client,
        query,
        configuration,
        namespace,
        watchPath,
        queryField,
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
