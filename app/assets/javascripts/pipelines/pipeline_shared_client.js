import VueApollo from 'vue-apollo';
import { IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';
import createDefaultClient from '~/lib/graphql';
import introspectionQueryResultData from './graphql/fragmentTypes.json';

export const fragmentMatcher = new IntrospectionFragmentMatcher({
  introspectionQueryResultData,
});

export const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
      cacheConfig: {
        fragmentMatcher,
      },
      useGet: true,
    },
  ),
});
