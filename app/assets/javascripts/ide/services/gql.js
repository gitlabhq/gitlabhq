import { memoize } from 'lodash';
import createGqClient, { fetchPolicies } from '~/lib/graphql';

/**
 * Returns a memoized client
 *
 * We defer creating the client so that importing this module does not cause any side-effects.
 * Creating the client immediately caused issues with miragejs where the gql client uses the
 * real fetch() instead of the shimmed one.
 */
const getClient = memoize(() =>
  createGqClient(
    {},
    {
      fetchPolicy: fetchPolicies.NO_CACHE,
    },
  ),
);

export const query = (...args) => getClient().query(...args);
export const mutate = (...args) => getClient().mutate(...args);
