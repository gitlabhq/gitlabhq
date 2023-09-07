import createDefaultClient, { createApolloClientWithCaching } from '~/lib/graphql';

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
  client = gon.features?.frontendCaching
    ? await createApolloClientWithCaching(
        {},
        { localCacheKey: 'service_desk_list', cacheConfig: { typePolicies } },
      )
    : createDefaultClient({}, { cacheConfig: { typePolicies } });
  return client;
}
