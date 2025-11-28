import { createApolloClientWithCaching } from '~/lib/graphql';
import { config } from '~/graphql_shared/issuable_client';

let client;

export async function gqlClient() {
  if (client) return client;
  client = await createApolloClientWithCaching(
    {},
    {
      localCacheKey: 'issues_list',
      ...config,
    },
  );
  return client;
}
