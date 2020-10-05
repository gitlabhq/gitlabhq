/**
 * @returns {Boolean} `true` if all the feature flags
 * required to enable the GraphQL endpoint are enabled
 */
export const useGraphQLEndpoint = rootState => {
  return Boolean(
    rootState.featureFlags.graphqlReleaseData &&
      rootState.featureFlags.graphqlReleasesPage &&
      rootState.featureFlags.graphqlMilestoneStats,
  );
};
