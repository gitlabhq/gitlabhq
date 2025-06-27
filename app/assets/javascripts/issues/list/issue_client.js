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
  // for now, we only enabled caching for legacy issues list so we use defaultClient for work items list
  // when we add caching to work items list, we can remove the query selector check
  const client =
    ['projects:issues:index', 'groups:issues'].includes(document.body.dataset.page) &&
    !document.querySelector('#js-work-items, [data-testid="work-item-router-view"]')
      ? await getIssuesClient()
      : defaultClient;
  return new VueApollo({ defaultClient: client });
}
