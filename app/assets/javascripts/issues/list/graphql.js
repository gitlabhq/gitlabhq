import produce from 'immer';
import createDefaultClient, { createApolloClientWithCaching } from '~/lib/graphql';
import getIssuesQuery from 'ee_else_ce/issues/list/queries/get_issues.query.graphql';
import { config } from '~/graphql_shared/issuable_client';

let client;

const resolvers = {
  Mutation: {
    reorderIssues: (_, { oldIndex, newIndex, namespace, serializedVariables }, { cache }) => {
      const variables = JSON.parse(serializedVariables);
      const sourceData = cache.readQuery({ query: getIssuesQuery, variables });

      const data = produce(sourceData, (draftData) => {
        const issues = draftData[namespace].issues.nodes.slice();
        const issueToMove = issues[oldIndex];
        issues.splice(oldIndex, 1);
        issues.splice(newIndex, 0, issueToMove);

        draftData[namespace].issues.nodes = issues;
      });

      cache.writeQuery({ query: getIssuesQuery, variables, data });
    },
  },
};

export async function gqlClient() {
  if (client) return client;
  client = gon.features?.frontendCaching
    ? await createApolloClientWithCaching(resolvers, { localCacheKey: 'issues_list', ...config })
    : createDefaultClient(resolvers, config);
  return client;
}
