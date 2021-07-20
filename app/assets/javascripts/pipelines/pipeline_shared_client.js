import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

export const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
      assumeImmutableResults: true,
      useGet: true,
    },
  ),
});
