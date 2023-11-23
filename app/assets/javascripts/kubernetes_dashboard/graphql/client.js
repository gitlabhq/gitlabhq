import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import typeDefs from '~/environments/graphql/typedefs.graphql';
import k8sPodsQuery from './queries/k8s_dashboard_pods.query.graphql';
import { resolvers } from './resolvers';

export const apolloProvider = () => {
  const defaultClient = createDefaultClient(resolvers, {
    typeDefs,
  });
  const { cache } = defaultClient;

  cache.writeQuery({
    query: k8sPodsQuery,
    data: {
      status: {
        phase: null,
      },
    },
  });

  return new VueApollo({
    defaultClient,
  });
};
