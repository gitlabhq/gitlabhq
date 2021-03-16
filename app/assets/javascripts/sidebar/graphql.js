import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

export const defaultClient = createDefaultClient();

export const apolloProvider = new VueApollo({
  defaultClient,
});
