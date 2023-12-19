import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import typeDefs from './typedefs.graphql';
import { resolvers } from './resolvers';

export const createApolloProvider = (endpoints) => {
  const defaultClient = createDefaultClient(resolvers(endpoints), {
    typeDefs,
    cacheConfig: {
      typePolicies: {
        Query: {
          fields: {
            currentScope: {
              read(data) {
                return data || 'enabledKeys';
              },
            },
            currentPage: {
              read(data) {
                return data || 1;
              },
            },
            pageInfo: {
              read(data) {
                return data || {};
              },
            },
            deployKeyToRemove: {
              read(data) {
                return data || null;
              },
            },
          },
        },
        LocalDeployKey: {
          deployKeysProjects: {
            merge(_, incoming) {
              return incoming;
            },
          },
        },
      },
    },
  });

  return new VueApollo({ defaultClient });
};
