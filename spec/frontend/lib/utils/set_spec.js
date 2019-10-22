import { isSubset } from '~/lib/utils/set';

describe('utils/set', () => {
  describe('isSubset', () => {
    it.each`
      subset                   | superset              | expected
      ${new Set()}             | ${new Set()}          | ${true}
      ${new Set()}             | ${new Set([1])}       | ${true}
      ${new Set([1])}          | ${new Set([1])}       | ${true}
      ${new Set([1, 3])}       | ${new Set([1, 2, 3])} | ${true}
      ${new Set([1])}          | ${new Set()}          | ${false}
      ${new Set([1])}          | ${new Set([2])}       | ${false}
      ${new Set([7, 8, 9])}    | ${new Set([1, 2, 3])} | ${false}
      ${new Set([1, 2, 3, 4])} | ${new Set([1, 2, 3])} | ${false}
    `('isSubset($subset, $superset) === $expected', ({ subset, superset, expected }) => {
      expect(isSubset(subset, superset)).toBe(expected);
    });
  });
});
