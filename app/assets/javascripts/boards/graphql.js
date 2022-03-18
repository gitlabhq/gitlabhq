import { defaultDataIdFromObject } from '@apollo/client/core';
import createDefaultClient from '~/lib/graphql';

export const gqlClient = createDefaultClient(
  {},
  {
    cacheConfig: {
      dataIdFromObject: (object) => {
        // eslint-disable-next-line no-underscore-dangle
        return object.__typename === 'BoardList' ? object.iid : defaultDataIdFromObject(object);
      },
    },
    batchMax: 2,
  },
);
