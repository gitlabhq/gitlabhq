import * as getters from '~/milestones/stores/getters';

describe('Milestone comboxbox Vuex store getters', () => {
  describe('isLoading', () => {
    it.each`
      requestCount | isLoading
      ${2}         | ${true}
      ${1}         | ${true}
      ${0}         | ${false}
      ${-1}        | ${false}
    `('returns true when at least one request is in progress', ({ requestCount, isLoading }) => {
      expect(getters.isLoading({ requestCount })).toBe(isLoading);
    });
  });

  describe('groupMilestonesEnabled', () => {
    it.each`
      groupId | groupMilestonesAvailable | groupMilestonesEnabled
      ${'1'}  | ${true}                  | ${true}
      ${'1'}  | ${false}                 | ${false}
      ${''}   | ${true}                  | ${false}
      ${''}   | ${false}                 | ${false}
      ${null} | ${true}                  | ${false}
    `(
      'returns true when groupId is a truthy string and groupMilestonesAvailable is true',
      ({ groupId, groupMilestonesAvailable, groupMilestonesEnabled }) => {
        expect(getters.groupMilestonesEnabled({ groupId, groupMilestonesAvailable })).toBe(
          groupMilestonesEnabled,
        );
      },
    );
  });
});
