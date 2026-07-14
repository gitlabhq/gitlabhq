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
          // Several label dropdowns share this cache entry and paginate
          // independently, so a plain concatPagination would append duplicate
          // labels. Dedupe by id to keep the merge idempotent.
          nodes: {
            merge(existing = [], incoming = [], { readField }) {
              const seen = new Set(existing.map((node) => readField('id', node)));
              const newNodes = incoming.filter((node) => !seen.has(readField('id', node)));
              return [...existing, ...newNodes];
            },
          },
        },
      },
    },
  },
});
