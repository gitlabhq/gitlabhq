import {
  Configuration,
  WatchApi,
  EVENT_TIMEOUT,
  EVENT_PLAIN_TEXT,
  EVENT_ERROR,
} from '@gitlab/cluster-client';
import { throttle } from 'lodash';
import k8sLogsQuery from '~/environments/graphql/queries/k8s_logs.query.graphql';
import k8sPodLogsWatcherQuery from '~/environments/graphql/queries/k8s_pod_logs_watcher.query.graphql';

export const buildWatchPath = ({ resource, api = 'api/v1', namespace = '' }) => {
  return `/${api}/namespaces/${namespace}/pods/${resource}/log`;
};

class LogsCacheWrapper {
  constructor(client, variables) {
    this.client = client;
    this.variables = variables;
  }

  writeLogsData(logsData) {
    this.client.writeQuery({
      query: k8sLogsQuery,
      data: { k8sLogs: { logs: logsData } },
      variables: this.variables,
    });
  }

  writeErrorData(error) {
    this.client.writeQuery({
      query: k8sLogsQuery,
      variables: this.variables,
      data: {
        k8sLogs: {
          error: { message: error.message },
        },
      },
    });
  }

  readLogsData() {
    return (
      this.client.readQuery({
        query: k8sLogsQuery,
        variables: this.variables,
      })?.k8sLogs?.logs || []
    );
  }
}

export const k8sLogs = (_, { configuration, namespace, podName, containerName }, { client }) => {
  const config = new Configuration(configuration);
  const watchApi = new WatchApi(config);
  const watchPath = buildWatchPath({ resource: podName, namespace });

  const variables = { configuration, namespace, podName, containerName };
  const cacheWrapper = new LogsCacheWrapper(client, variables);

  const watchQuery = { follow: true };
  if (containerName) watchQuery.container = containerName;

  watchApi
    .subscribeToStream(watchPath, watchQuery)
    .then((watcher) => {
      client.writeQuery({
        query: k8sPodLogsWatcherQuery,
        data: { k8sPodLogsWatcher: { watcher } },
        variables,
      });

      let logsData = [];
      const writeLogsThrottled = throttle(() => {
        const currentLogsData = cacheWrapper.readLogsData();

        if (currentLogsData.length !== logsData.length) {
          cacheWrapper.writeLogsData(logsData);
        }
      }, 100);

      watcher.on(EVENT_PLAIN_TEXT, (data) => {
        logsData = [...logsData, { id: logsData.length + 1, content: data }];

        writeLogsThrottled();
      });

      watcher.on(EVENT_TIMEOUT, (err) => {
        cacheWrapper.writeErrorData(err);
      });

      watcher.on(EVENT_ERROR, (err) => {
        cacheWrapper.writeErrorData(err);
      });
    })
    .catch((err) => {
      cacheWrapper.writeErrorData(err);
    });
};

export const abortK8sPodLogsStream = (
  _,
  { configuration, namespace, podName, containerName },
  { client },
) => {
  const podLogsWatcher = client.readQuery({
    query: k8sPodLogsWatcherQuery,
    variables: { configuration, namespace, podName, containerName },
  })?.k8sPodLogsWatcher?.watcher;

  podLogsWatcher?.abortStream();
};

export const k8sPodLogsWatcher = () => ({ watcher: null });
