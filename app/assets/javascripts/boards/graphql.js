import { IntrospectionFragmentMatcher, defaultDataIdFromObject } from 'apollo-cache-inmemory';
import createDefaultClient from '~/lib/graphql';
import introspectionQueryResultData from '~/sidebar/fragmentTypes.json';

const fragmentMatcher = new IntrospectionFragmentMatcher({
  introspectionQueryResultData,
});

export const gqlClient = createDefaultClient(
  {},
  {
    cacheConfig: {
      dataIdFromObject: (object) => {
        // eslint-disable-next-line no-underscore-dangle
        return object.__typename === 'BoardList' ? object.iid : defaultDataIdFromObject(object);
      },

      fragmentMatcher,
    },
  },
);
