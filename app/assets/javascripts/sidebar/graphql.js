import { IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';
import produce from 'immer';
import VueApollo from 'vue-apollo';
import getIssueStateQuery from '~/issue_show/queries/get_issue_state.query.graphql';
import createDefaultClient from '~/lib/graphql';
import introspectionQueryResultData from './fragmentTypes.json';

const fragmentMatcher = new IntrospectionFragmentMatcher({
  introspectionQueryResultData,
});

const resolvers = {
  Mutation: {
    updateIssueState: (_, { issueType = undefined, isDirty = false }, { cache }) => {
      const sourceData = cache.readQuery({ query: getIssueStateQuery });
      const data = produce(sourceData, (draftData) => {
        draftData.issueState = { issueType, isDirty };
      });
      cache.writeQuery({ query: getIssueStateQuery, data });
    },
  },
};

export const defaultClient = createDefaultClient(resolvers, {
  cacheConfig: {
    fragmentMatcher,
  },
  assumeImmutableResults: true,
});

export const apolloProvider = new VueApollo({
  defaultClient,
});
