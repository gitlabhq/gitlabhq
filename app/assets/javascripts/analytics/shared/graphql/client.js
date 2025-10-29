import { concatPagination } from '@apollo/client/utilities';
import createDefaultClient from '~/lib/graphql';
import { resolvers } from './resolvers';
import typeDefs from './typedefs.graphql';

export const defaultClient = createDefaultClient(resolvers, {
  typeDefs,
  cacheConfig: {
    typePolicies: {
      Group: {
        fields: {
          labels: {
            keyArgs: ['fullPath', 'searchTerm'],
          },
        },
      },
      LabelConnection: {
        fields: {
          nodes: concatPagination(),
        },
      },
    },
  },
});
