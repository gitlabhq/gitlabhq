import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import environmentApp from './queries/environment_app.query.graphql';
import pageInfoQuery from './queries/page_info.query.graphql';
import environmentToDeleteQuery from './queries/environment_to_delete.query.graphql';
import environmentToRollbackQuery from './queries/environment_to_rollback.query.graphql';
import environmentToStopQuery from './queries/environment_to_stop.query.graphql';
import k8sPodsQuery from './queries/k8s_pods.query.graphql';
import k8sServicesQuery from './queries/k8s_services.query.graphql';
import { resolvers } from './resolvers';
import typeDefs from './typedefs.graphql';

export const apolloProvider = (endpoint) => {
  const defaultClient = createDefaultClient(resolvers(endpoint), {
    typeDefs,
    useGet: true,
  });
  const { cache } = defaultClient;

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
    data: {
      status: {
        phase: null,
      },
    },
  });
  cache.writeQuery({
    query: k8sServicesQuery,
    data: {
      metadata: {
        name: null,
        namespace: null,
        creationTimestamp: null,
      },
      spec: {
        type: null,
        clusterIP: null,
        externalIP: null,
        ports: [],
      },
    },
  });
  return new VueApollo({
    defaultClient,
  });
};
