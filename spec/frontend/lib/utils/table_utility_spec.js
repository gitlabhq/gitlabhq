import * as tableUtils from '~/lib/utils/table_utility';

describe('table_utility', () => {
  describe('sortObjectToString', () => {
    it('returns the expected sorting string ending in "DESC" when sortDesc is true', () => {
      expect(tableUtils.sortObjectToString({ sortBy: 'mergedAt', sortDesc: true })).toBe(
        'MERGED_AT_DESC',
      );
    });

    it('returns the expected sorting string ending in "ASC" when sortDesc is false', () => {
      expect(tableUtils.sortObjectToString({ sortBy: 'mergedAt', sortDesc: false })).toBe(
        'MERGED_AT_ASC',
      );
    });
  });

  describe('sortStringToObject', () => {
    it.each`
      sortBy        | sortDesc | sortString
      ${'mergedAt'} | ${true}  | ${'MERGED_AT_DESC'}
      ${'mergedAt'} | ${false} | ${'MERGED_AT_ASC'}
      ${'severity'} | ${true}  | ${'SEVERITY_DESC'}
      ${'severity'} | ${false} | ${'SEVERITY_ASC'}
      ${null}       | ${null}  | ${'SEVERITY'}
      ${null}       | ${null}  | ${''}
    `(
      'returns the expected sort object when the sort string is "$sortString"',
      ({ sortBy, sortDesc, sortString }) => {
        expect(tableUtils.sortStringToObject(sortString)).toStrictEqual({ sortBy, sortDesc });
      },
    );
  });
});
