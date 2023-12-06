import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import typeDefs from '~/environments/graphql/typedefs.graphql';
import k8sPodsQuery from './queries/k8s_dashboard_pods.query.graphql';
import k8sDeploymentsQuery from './queries/k8s_dashboard_deployments.query.graphql';
import { resolvers } from './resolvers';

export const apolloProvider = () => {
  const defaultClient = createDefaultClient(resolvers, {
    typeDefs,
  });
  const { cache } = defaultClient;

  cache.writeQuery({
    query: k8sPodsQuery,
    data: {
      metadata: {
        name: null,
        namespace: null,
        creationTimestamp: null,
        labels: null,
        annotations: null,
      },
      status: {
        phase: null,
      },
    },
  });

  cache.writeQuery({
    query: k8sDeploymentsQuery,
    data: {
      metadata: {
        name: null,
        namespace: null,
        creationTimestamp: null,
        labels: null,
        annotations: null,
      },
      status: {
        conditions: null,
      },
    },
  });

  return new VueApollo({
    defaultClient,
  });
};
