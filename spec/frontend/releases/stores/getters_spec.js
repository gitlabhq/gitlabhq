import * as getters from '~/releases/stores/getters';

describe('~/releases/stores/getters.js', () => {
  it.each`
    graphqlReleaseData | graphqlReleasesPage | graphqlMilestoneStats | result
    ${false}           | ${false}            | ${false}              | ${false}
    ${false}           | ${false}            | ${true}               | ${false}
    ${false}           | ${true}             | ${false}              | ${false}
    ${false}           | ${true}             | ${true}               | ${false}
    ${true}            | ${false}            | ${false}              | ${false}
    ${true}            | ${false}            | ${true}               | ${false}
    ${true}            | ${true}             | ${false}              | ${false}
    ${true}            | ${true}             | ${true}               | ${true}
  `(
    'returns $result with feature flag values graphqlReleaseData=$graphqlReleaseData, graphqlReleasesPage=$graphqlReleasesPage, and graphqlMilestoneStats=$graphqlMilestoneStats',
    ({ result: expectedResult, ...featureFlags }) => {
      const actualResult = getters.useGraphQLEndpoint({ featureFlags });

      expect(actualResult).toBe(expectedResult);
    },
  );
});
