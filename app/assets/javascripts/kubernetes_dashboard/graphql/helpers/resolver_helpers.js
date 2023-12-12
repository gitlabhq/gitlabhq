import { CoreV1Api, Configuration, WatchApi, EVENT_DATA } from '@gitlab/cluster-client';

export const handleClusterError = async (err) => {
  if (!err.response) {
    throw err;
  }

  const errorData = await err.response.json();
  throw errorData;
};

export const buildWatchPath = ({ resource, api = 'api/v1', namespace = '' }) => {
  return namespace ? `/${api}/namespaces/${namespace}/${resource}` : `/${api}/${resource}`;
};

export const mapWorkloadItem = (item) => {
  if (item.metadata) {
    const metadata = {
      ...item.metadata,
      annotations: item.metadata?.annotations || {},
      labels: item.metadata?.labels || {},
    };
    return { status: item.status, metadata };
  }
  return { status: item.status };
};

export const mapSetItem = (item) => {
  const status = {
    ...item.status,
    readyReplicas: item.status?.readyReplicas || null,
  };

  const metadata =
    {
      ...item.metadata,
      annotations: item.metadata?.annotations || {},
      labels: item.metadata?.labels || {},
    } || null;

  const spec = item.spec || null;

  return { status, metadata, spec };
};

export const watchWorkloadItems = ({
  client,
  query,
  configuration,
  namespace,
  watchPath,
  queryField,
  mapFn = mapWorkloadItem,
}) => {
  const config = new Configuration(configuration);
  const watcherApi = new WatchApi(config);

  watcherApi
    .subscribeToStream(watchPath, { watch: true })
    .then((watcher) => {
      let result = [];

      watcher.on(EVENT_DATA, (data) => {
        result = data.map(mapFn);

        client.writeQuery({
          query,
          variables: { configuration, namespace },
          data: { [queryField]: result },
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
  enableWatch = false,
}) => {
  const config = new Configuration(configuration);

  const coreV1Api = new CoreV1Api(config);
  const podsApi = namespace
    ? coreV1Api.listCoreV1NamespacedPod({ namespace })
    : coreV1Api.listCoreV1PodForAllNamespaces();

  return podsApi
    .then((res) => {
      if (enableWatch) {
        const watchPath = buildWatchPath({ resource: 'pods', namespace });
        watchWorkloadItems({
          client,
          query,
          configuration,
          namespace,
          watchPath,
          queryField: 'k8sPods',
        });
      }

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
};
