import produce from 'immer';
import VueApollo from 'vue-apollo';
import getIssueStateQuery from '~/issues/show/queries/get_issue_state.query.graphql';
import createDefaultClient from '~/lib/graphql';
import { temporaryConfig, resolvers as workItemResolvers } from '~/work_items/graphql/provider';

const resolvers = {
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

export const defaultClient = createDefaultClient(
  resolvers,
  // should be removed with the rollout of work item assignees FF
  // https://gitlab.com/gitlab-org/gitlab/-/issues/363030
  temporaryConfig,
);

export const apolloProvider = new VueApollo({
  defaultClient,
});
