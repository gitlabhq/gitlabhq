import { ApolloLink } from '@apollo/client/core';
import { memoize } from 'lodash';

export const FEATURE_CATEGORY_HEADER = 'x-gitlab-feature-category';

/**
 * Returns the ApolloLink (or null) used to add instrumentation metadata to the GraphQL request.
 *
 * - The result will be null if the `feature_category` cannot be found.
 * - The result is memoized since we don't need to reevaluate this every time we create a client
 */
export const getInstrumentationLink = memoize(() => {
  return new ApolloLink((operation, forward) => {
    operation.setContext((currentContext) => {
      const { feature_category: featureCategory } = gon;

      if (!featureCategory) return currentContext;

      return {
        ...currentContext,
        headers: {
          ...currentContext?.headers,
          [FEATURE_CATEGORY_HEADER]: featureCategory,
        },
      };
    });

    return forward(operation);
  });
});
