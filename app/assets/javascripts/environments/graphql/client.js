import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import environmentApp from './queries/environment_app.query.graphql';
import pageInfoQuery from './queries/page_info.query.graphql';
import { resolvers } from './resolvers';
import typeDefs from './typedefs.graphql';

export const apolloProvider = (endpoint) => {
  const defaultClient = createDefaultClient(resolvers(endpoint), {
    typeDefs,
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
  return new VueApollo({
    defaultClient,
  });
};
