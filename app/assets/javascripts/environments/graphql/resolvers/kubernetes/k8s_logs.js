import {
  Configuration,
  WatchApi,
  EVENT_TIMEOUT,
  EVENT_PLAIN_TEXT,
  EVENT_ERROR,
} from '@gitlab/cluster-client';
import k8sLogsQuery from '~/environments/graphql/queries/k8s_logs.query.graphql';

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

export const k8sLogs = (_, { configuration, namespace, podName }, { client }) => {
  const config = new Configuration(configuration);
  const watchApi = new WatchApi(config);
  const watchPath = buildWatchPath({ resource: podName, namespace });

  const variables = { configuration, namespace, podName };
  const cacheWrapper = new LogsCacheWrapper(client, variables);

  watchApi
    .subscribeToStream(watchPath, { follow: true })
    .then((watcher) => {
      watcher.on(EVENT_PLAIN_TEXT, (data) => {
        const logsData = cacheWrapper.readLogsData();

        const updatedLogsData = [...logsData, { id: logsData.length + 1, content: data }];

        cacheWrapper.writeLogsData(updatedLogsData);
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
