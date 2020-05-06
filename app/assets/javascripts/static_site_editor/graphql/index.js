import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import typeDefs from './typedefs.graphql';

Vue.use(VueApollo);

const createApolloProvider = data => {
  const defaultClient = createDefaultClient(
    {},
    {
      typeDefs,
    },
  );

  defaultClient.cache.writeData({
    data,
  });

  return new VueApollo({
    defaultClient,
  });
};

export default createApolloProvider;
