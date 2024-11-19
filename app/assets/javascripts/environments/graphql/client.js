import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import pageInfoQuery from '~/graphql_shared/client/page_info.query.graphql';
import environmentApp from './queries/environment_app.query.graphql';
import environmentToDeleteQuery from './queries/environment_to_delete.query.graphql';
import environmentToRollbackQuery from './queries/environment_to_rollback.query.graphql';
import environmentToStopQuery from './queries/environment_to_stop.query.graphql';
import k8sPodsQuery from './queries/k8s_pods.query.graphql';
import k8sConnectionStatusQuery from './queries/k8s_connection_status.query.graphql';
import k8sLogsQuery from './queries/k8s_logs.query.graphql';
import k8sServicesQuery from './queries/k8s_services.query.graphql';
import k8sDeploymentsQuery from './queries/k8s_deployments.query.graphql';
import k8sNamespacesQuery from './queries/k8s_namespaces.query.graphql';
import fluxKustomizationQuery from './queries/flux_kustomization.query.graphql';
import fluxHelmReleaseQuery from './queries/flux_helm_release.query.graphql';
import k8sEventsQuery from './queries/k8s_events.query.graphql';
import k8sPodLogsWatcherQuery from './queries/k8s_pod_logs_watcher.query.graphql';
import { resolvers } from './resolvers';
import typeDefs from './typedefs.graphql';
import { connectionStatus } from './resolvers/kubernetes/constants';

export const apolloProvider = (endpoint) => {
  const defaultClient = createDefaultClient(resolvers(endpoint), {
    typeDefs,
  });
  const { cache } = defaultClient;

  const k8sMetadata = {
    name: null,
    namespace: null,
    creationTimestamp: null,
    labels: null,
    annotations: null,
  };
  const k8sData = { nodes: { metadata: k8sMetadata, status: {}, spec: {} } };

  cache.writeQuery({
    query: environmentApp,
    data: {
      availableCount: 0,
      environments: [],
      reviewApp: {},
      stoppedCount: 0,
    },
  });

  cache.writeQuery({
    query: pageInfoQuery,
    data: {
      pageInfo: {
        total: 0,
        perPage: 20,
        nextPage: 0,
        previousPage: 0,
        __typename: 'LocalPageInfo',
      },
    },
  });

  cache.writeQuery({
    query: environmentToDeleteQuery,
    data: {
      environmentToDelete: {
        name: 'null',
        __typename: 'LocalEnvironment',
        id: '0',
        deletePath: null,
        folderPath: null,
        retryUrl: null,
        autoStopPath: null,
        lastDeployment: null,
      },
    },
  });
  cache.writeQuery({
    query: environmentToStopQuery,
    data: {
      environmentToStop: {
        name: 'null',
        __typename: 'LocalEnvironment',
        id: '0',
        deletePath: null,
        folderPath: null,
        retryUrl: null,
        autoStopPath: null,
        lastDeployment: null,
      },
    },
  });
  cache.writeQuery({
    query: environmentToRollbackQuery,
    data: {
      environmentToRollback: {
        name: 'null',
        __typename: 'LocalEnvironment',
        id: '0',
        deletePath: null,
        folderPath: null,
        retryUrl: null,
        autoStopPath: null,
        lastDeployment: null,
      },
    },
  });
  cache.writeQuery({
    query: k8sPodsQuery,
    data: k8sData,
  });
  cache.writeQuery({
    query: k8sConnectionStatusQuery,
    data: {
      k8sConnection: {
        k8sPods: {
          connectionStatus: connectionStatus.disconnected,
        },
        k8sServices: {
          connectionStatus: connectionStatus.disconnected,
        },
      },
    },
  });
  cache.writeQuery({
    query: k8sServicesQuery,
    data: k8sData,
  });
  cache.writeQuery({
    query: k8sNamespacesQuery,
    data: {
      metadata: {
        name: null,
      },
    },
  });
  cache.writeQuery({
    query: fluxKustomizationQuery,
    data: {
      ...k8sData,
      kind: '',
      conditions: {
        message: '',
        reason: '',
        status: '',
        type: '',
      },
      inventory: [],
    },
  });
  cache.writeQuery({
    query: fluxHelmReleaseQuery,
    data: {
      ...k8sData,
      kind: '',
      conditions: {
        message: '',
        reason: '',
        status: '',
        type: '',
      },
    },
  });
  cache.writeQuery({
    query: k8sDeploymentsQuery,
    data: {
      metadata: {
        name: null,
      },
      status: {},
    },
  });
  cache.writeQuery({
    query: k8sLogsQuery,
    data: { logs: [] },
  });

  cache.writeQuery({
    query: k8sEventsQuery,
    data: {
      lastTimestamp: '',
      eventTime: '',
      message: '',
      reason: '',
      source: {},
      type: '',
    },
  });

  cache.writeQuery({
    query: k8sPodLogsWatcherQuery,
    data: {
      k8sPodLogsWatcher: {
        watcher: null,
      },
    },
  });

  return new VueApollo({
    defaultClient,
  });
};
