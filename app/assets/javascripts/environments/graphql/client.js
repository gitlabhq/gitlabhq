import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import environmentApp from './queries/environmentApp.query.graphql';
import { resolvers } from './resolvers';
import typedefs from './typedefs.graphql';

export const apolloProvider = (endpoint) => {
  const defaultClient = createDefaultClient(
    resolvers(endpoint),
    {
      assumeImmutableResults: true,
    },
    typedefs,
  );
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
  return new VueApollo({
    defaultClient,
  });
};
