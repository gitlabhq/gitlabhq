import { createApolloClientWithCaching } from '~/lib/graphql';

let client;

const typePolicies = {
  Project: {
    fields: {
      issues: {
        merge: true,
      },
    },
  },
};

export async function gqlClient() {
  if (client) return client;
  client = await createApolloClientWithCaching(
    {},
    { localCacheKey: 'service_desk_list', cacheConfig: { typePolicies } },
  );
  return client;
}
