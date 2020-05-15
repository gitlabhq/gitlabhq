import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import typeDefs from './typedefs.graphql';
import fileResolver from './resolvers/file';
import submitContentChangesResolver from './resolvers/submit_content_changes';

Vue.use(VueApollo);

const createApolloProvider = appData => {
  const defaultClient = createDefaultClient(
    {
      Project: {
        file: fileResolver,
      },
      Mutation: {
        submitContentChanges: submitContentChangesResolver,
      },
    },
    {
      typeDefs,
    },
  );

  defaultClient.cache.writeData({
    data: {
      appData: {
        __typename: 'AppData',
        ...appData,
      },
    },
  });

  return new VueApollo({
    defaultClient,
  });
};

export default createApolloProvider;
