import {
  getQueryParams,
  keyValueToFilterToken,
  searchArrayToFilterTokens,
} from '~/packages_and_registries/shared/utils';

describe('Packages And Registries shared utils', () => {
  describe('getQueryParams', () => {
    it('returns an object from a query string, with arrays', () => {
      const queryString = 'foo=bar&baz[]=1&baz[]=2';

      expect(getQueryParams(queryString)).toStrictEqual({ foo: 'bar', baz: ['1', '2'] });
    });
  });

  describe('keyValueToFilterToken', () => {
    it('returns an object in the correct form', () => {
      const type = 'myType';
      const data = 1;

      expect(keyValueToFilterToken(type, data)).toStrictEqual({ type, value: { data } });
    });
  });

  describe('searchArrayToFilterTokens', () => {
    it('returns an array of objects in the correct form', () => {
      const search = ['one', 'two'];

      expect(searchArrayToFilterTokens(search)).toStrictEqual([
        { type: 'filtered-search-term', value: { data: 'one' } },
        { type: 'filtered-search-term', value: { data: 'two' } },
      ]);
    });
  });
});
