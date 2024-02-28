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
      if (enableWatch) {
        const watchPath = buildWatchPath({ resource: 'pods', namespace });
        watchWorkloadItems({
          client,
          query,
          configuration,
          namespace,
          watchPath,
          queryField,
        });
      }

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
