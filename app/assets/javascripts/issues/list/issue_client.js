import VueApollo from 'vue-apollo';
import { config, defaultClient, resolvers } from '~/graphql_shared/issuable_client';
import { createApolloClientWithCaching } from '~/lib/graphql';

let issuesClientPromise;

async function getIssuesClient() {
  if (issuesClientPromise) return issuesClientPromise;
  issuesClientPromise = createApolloClientWithCaching(resolvers, {
    localCacheKey: 'issues_list',
    ...config,
  });
  return issuesClientPromise;
}

export async function getApolloProvider() {
  const client = ['projects:issues:index', 'groups:issues'].includes(document.body.dataset.page)
    ? await getIssuesClient()
    : defaultClient;
  return new VueApollo({ defaultClient: client });
}
