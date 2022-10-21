import { makeVar } from '@apollo/client/core';
import { RUNNER_TYPENAME } from '../../constants';
import typeDefs from './typedefs.graphql';

/**
 * Local state for checkable runner items.
 *
 * Usage:
 *
 * ```
 * import { createLocalState } from '~/ci/runner/graphql/list/local_state';
 *
 * // initialize local state
 * const { cacheConfig, typeDefs, localMutations } = createLocalState();
 *
 * // configure the client
 * apolloClient = createApolloClient({}, { cacheConfig, typeDefs });
 *
 * // modify local state
 * localMutations.setRunnerChecked( ... )
 * ```
 *
 * @returns {Object} An object to configure an Apollo client:
 * contains cacheConfig, typeDefs, localMutations.
 */
export const createLocalState = () => {
  const checkedRunnerIdsVar = makeVar({});

  const cacheConfig = {
    typePolicies: {
      Query: {
        fields: {
          checkedRunnerIds(_, { canRead, toReference }) {
            return Object.entries(checkedRunnerIdsVar())
              .filter(([id]) => {
                // Some runners may be deleted by the user separately.
                // Skip dangling references, those not in the cache.
                // See: https://www.apollographql.com/docs/react/caching/garbage-collection/#dangling-references
                return canRead(toReference({ __typename: RUNNER_TYPENAME, id }));
              })
              .filter(([, isChecked]) => isChecked)
              .map(([id]) => id);
          },
        },
      },
    },
  };

  const localMutations = {
    setRunnerChecked({ runner, isChecked }) {
      const { id, userPermissions } = runner;
      if (userPermissions?.deleteRunner) {
        checkedRunnerIdsVar({
          ...checkedRunnerIdsVar(),
          [id]: isChecked,
        });
      }
    },
    setRunnersChecked({ runners, isChecked }) {
      const newVal = runners
        .filter(({ userPermissions }) => userPermissions?.deleteRunner)
        .reduce((acc, { id }) => ({ ...acc, [id]: isChecked }), checkedRunnerIdsVar());
      checkedRunnerIdsVar(newVal);
    },
    clearChecked() {
      checkedRunnerIdsVar({});
    },
  };

  return {
    cacheConfig,
    typeDefs,
    localMutations,
  };
};
