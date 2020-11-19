import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import typeDefs from './typedefs.graphql';
import fileResolver from './resolvers/file';
import submitContentChangesResolver from './resolvers/submit_content_changes';
import hasSubmittedChangesResolver from './resolvers/has_submitted_changes';

Vue.use(VueApollo);

const createApolloProvider = appData => {
  const defaultClient = createDefaultClient(
    {
      Project: {
        file: fileResolver,
      },
      Mutation: {
        submitContentChanges: submitContentChangesResolver,
        hasSubmittedChanges: hasSubmittedChangesResolver,
      },
    },
    {
      typeDefs,
      assumeImmutableResults: true,
    },
  );

  // eslint-disable-next-line @gitlab/require-i18n-strings
  const mounts = appData.mounts.map(mount => ({ __typename: 'Mount', ...mount }));

  defaultClient.cache.writeData({
    data: {
      appData: {
        __typename: 'AppData',
        ...appData,
        mounts,
      },
    },
  });

  return new VueApollo({
    defaultClient,
  });
};

export default createApolloProvider;
