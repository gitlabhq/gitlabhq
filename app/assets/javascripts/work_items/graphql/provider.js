import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

export function createApolloProvider() {
  Vue.use(VueApollo);

  const defaultClient = createDefaultClient();

  return new VueApollo({
    defaultClient,
  });
}
