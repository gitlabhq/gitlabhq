import produce from 'immer';
import VueApollo from 'vue-apollo';
import getIssueStateQuery from '~/issues/show/queries/get_issue_state.query.graphql';
import { resolvers as workItemResolvers } from '~/work_items/graphql/resolvers';
import createDefaultClient from '~/lib/graphql';

const resolvers = {
  ...workItemResolvers,
  Mutation: {
    updateIssueState: (_, { issueType = undefined, isDirty = false }, { cache }) => {
      const sourceData = cache.readQuery({ query: getIssueStateQuery });
      const data = produce(sourceData, (draftData) => {
        draftData.issueState = { issueType, isDirty };
      });
      cache.writeQuery({ query: getIssueStateQuery, data });
    },
    ...workItemResolvers.Mutation,
  },
};

export const defaultClient = createDefaultClient(resolvers);

export const apolloProvider = new VueApollo({
  defaultClient,
});
