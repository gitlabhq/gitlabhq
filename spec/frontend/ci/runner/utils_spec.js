import {
  formatJobCount,
  tableField,
  getPaginationVariables,
  parseInterval,
} from '~/ci/runner/utils';

describe('~/ci/runner/utils', () => {
  describe('formatJobCount', () => {
    it('formats a number', () => {
      expect(formatJobCount(1)).toBe('1');
      expect(formatJobCount(99)).toBe('99');
    });

    it('formats a large count', () => {
      expect(formatJobCount(1000)).toBe('1,000');
      expect(formatJobCount(1001)).toBe('1,000+');
    });

    it('returns an empty string for non-numeric values', () => {
      expect(formatJobCount(undefined)).toBe('');
      expect(formatJobCount(null)).toBe('');
      expect(formatJobCount('number')).toBe('');
    });
  });

  describe('tableField', () => {
    it('a field with options', () => {
      expect(tableField({ key: 'name' })).toEqual({
        key: 'name',
        label: '',
        tdAttr: { 'data-testid': 'td-name' },
        thClass: expect.any(Array),
      });
    });

    it('a field with a label', () => {
      const label = 'A field name';

      expect(tableField({ key: 'name', label })).toMatchObject({
        label,
      });
    });

    it('a field with custom classes', () => {
      const mockClasses = ['foo', 'bar'];

      expect(tableField({ thClasses: mockClasses })).toMatchObject({
        thClass: expect.arrayContaining(mockClasses),
      });
    });

    it('a field with custom options', () => {
      expect(tableField({ foo: 'bar' })).toMatchObject({ foo: 'bar' });
    });
  });

  describe('getPaginationVariables', () => {
    const after = 'AFTER_CURSOR';
    const before = 'BEFORE_CURSOR';

    it.each`
      case                         | pagination    | pageSize     | variables
      ${'next page'}               | ${{ after }}  | ${undefined} | ${{ after, first: 10 }}
      ${'prev page'}               | ${{ before }} | ${undefined} | ${{ before, last: 10 }}
      ${'first page'}              | ${{}}         | ${undefined} | ${{ first: 10 }}
      ${'next page with N items'}  | ${{ after }}  | ${20}        | ${{ after, first: 20 }}
      ${'prev page with N items'}  | ${{ before }} | ${20}        | ${{ before, last: 20 }}
      ${'first page with N items'} | ${{}}         | ${20}        | ${{ first: 20 }}
    `('navigates to $case', ({ pagination, pageSize, variables }) => {
      expect(getPaginationVariables(pagination, pageSize)).toEqual(variables);
    });
  });

  describe('parseInterval', () => {
    it.each`
      case                            | argument     | returnValue
      ${'parses integer'}             | ${'86400'}   | ${86400}
      ${'returns null for undefined'} | ${undefined} | ${null}
      ${'returns null for null'}      | ${null}      | ${null}
    `('$case', ({ argument, returnValue }) => {
      expect(parseInterval(argument)).toStrictEqual(returnValue);
    });
  });
});
