import { EVENT_TIMEOUT, EVENT_PLAIN_TEXT, EVENT_ERROR } from '@gitlab/cluster-client';
import throttle from 'lodash/throttle';
import k8sLogsQuery from '~/environments/graphql/queries/k8s_logs.query.graphql';
import k8sPodLogsWatcherQuery from '~/environments/graphql/queries/k8s_pod_logs_watcher.query.graphql';
import {
  buildWatchPath,
  k8sLogs,
  abortK8sPodLogsStream,
} from '~/environments/graphql/resolvers/kubernetes/k8s_logs';
import { bootstrapWatcherMock } from '../watcher_mock_helper';

jest.mock('lodash/throttle', () => jest.fn());

let watchStream;
const configuration = {
  basePath: 'kas-proxy/',
  baseOptions: {
    headers: { 'GitLab-Agent-Id': '1' },
  },
};

const podName = 'test-pod';
const namespace = 'default';
const client = { writeQuery: jest.fn(), readQuery: jest.fn() };

describe('buildWatchPath', () => {
  it('should return the correct path with namespace', () => {
    const resource = 'my-pod';
    const api = 'api/v1';
    const path = buildWatchPath({ resource, api, namespace });
    expect(path).toBe(`/${api}/namespaces/${namespace}/pods/${resource}/log`);
  });
});

describe('k8sLogs', () => {
  beforeEach(() => {
    watchStream = bootstrapWatcherMock();
  });

  it('should request pods logs if no container is specified', async () => {
    await k8sLogs(null, { configuration, namespace, podName }, { client });

    expect(watchStream.subscribeToStreamMock).toHaveBeenCalledWith(
      '/api/v1/namespaces/default/pods/test-pod/log',
      { follow: true },
    );
  });

  it('should request specific container logs if container is specified', async () => {
    const containerName = 'my-container';
    await k8sLogs(null, { configuration, namespace, podName, containerName }, { client });

    expect(watchStream.subscribeToStreamMock).toHaveBeenCalledWith(
      '/api/v1/namespaces/default/pods/test-pod/log',
      {
        follow: true,
        container: containerName,
      },
    );
  });

  throttle.mockImplementation(jest.requireActual('lodash/throttle'));
  const errorMessage = 'event error message';
  const logContent = 'Plain text log data';
  it.each([
    [EVENT_PLAIN_TEXT, logContent, { logs: [{ content: logContent, id: 1 }] }],
    [EVENT_TIMEOUT, { message: errorMessage }, { error: { message: errorMessage } }],
    [EVENT_ERROR, { message: errorMessage }, { error: { message: errorMessage } }],
  ])(
    'when "%s" event is received should update logs data',
    async (eventName, eventData, expectedData) => {
      await k8sLogs(null, { configuration, namespace, podName }, { client });

      watchStream.triggerEvent(eventName, eventData);

      if (eventName === EVENT_PLAIN_TEXT) {
        expect(throttle).toHaveBeenCalledTimes(1);
        expect(throttle).toHaveBeenCalledWith(expect.any(Function), 100);
      }

      jest.runOnlyPendingTimers();

      expect(client.writeQuery).toHaveBeenCalledWith({
        query: k8sLogsQuery,
        variables: {
          namespace,
          configuration,
          podName,
        },
        data: {
          k8sLogs: expectedData,
        },
      });
    },
  );

  it('should update `k8sPodLogsWatcher` query with the watcher', async () => {
    await k8sLogs(null, { configuration, namespace, podName }, { client });

    watchStream.triggerEvent(EVENT_PLAIN_TEXT, 'Log data');

    expect(client.writeQuery).toHaveBeenCalledWith({
      query: k8sPodLogsWatcherQuery,
      variables: {
        namespace,
        configuration,
        podName,
      },
      data: {
        k8sPodLogsWatcher: { watcher: {} },
      },
    });
  });
});

describe('abortK8sPodLogsStream', () => {
  beforeEach(() => {
    watchStream = bootstrapWatcherMock();
  });

  it('should read `k8sPodLogsWatcher` query to get the watcher', async () => {
    await abortK8sPodLogsStream(
      null,
      {
        configuration,
        namespace,
        podName,
      },
      { client },
    );

    expect(client.readQuery).toHaveBeenCalledWith({
      query: k8sPodLogsWatcherQuery,
      variables: {
        namespace,
        configuration,
        podName,
      },
    });
  });

  it('should abort the stream when the watcher is available', async () => {
    client.readQuery.mockReturnValue({ k8sPodLogsWatcher: { watcher: watchStream } });
    await abortK8sPodLogsStream(
      null,
      {
        configuration,
        namespace,
        podName,
      },
      { client },
    );

    expect(watchStream.abortStream).toHaveBeenCalledTimes(1);
  });
});
