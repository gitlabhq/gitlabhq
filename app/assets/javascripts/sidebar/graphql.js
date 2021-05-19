import { IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import introspectionQueryResultData from './fragmentTypes.json';

const fragmentMatcher = new IntrospectionFragmentMatcher({
  introspectionQueryResultData,
});

export const defaultClient = createDefaultClient(
  {},
  {
    cacheConfig: {
      fragmentMatcher,
    },
    assumeImmutableResults: true,
  },
);

export const apolloProvider = new VueApollo({
  defaultClient,
});
