import { ApolloLink } from '@apollo/client/core';
import { memoize } from 'lodash';

export const FEATURE_CATEGORY_HEADER = 'x-gitlab-feature-category';

/**
 * Returns the ApolloLink (or null) used to add instrumentation metadata to the GraphQL request.
 *
 * - The result will be null if the `feature_category` cannot be found.
 * - The result is memoized since the `feature_category` is the same for the entire page.
 */
export const getInstrumentationLink = memoize(() => {
  const { feature_category: featureCategory } = gon;

  if (!featureCategory) {
    return null;
  }

  return new ApolloLink((operation, forward) => {
    operation.setContext(({ headers = {} }) => ({
      headers: {
        ...headers,
        [FEATURE_CATEGORY_HEADER]: featureCategory,
      },
    }));

    return forward(operation);
  });
});
