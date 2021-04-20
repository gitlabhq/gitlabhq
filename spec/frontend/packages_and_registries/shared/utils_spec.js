import { FILTERED_SEARCH_TERM } from '~/packages_and_registries/shared/constants';
import {
  getQueryParams,
  keyValueToFilterToken,
  searchArrayToFilterTokens,
  extractFilterAndSorting,
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
        { type: FILTERED_SEARCH_TERM, value: { data: 'one' } },
        { type: FILTERED_SEARCH_TERM, value: { data: 'two' } },
      ]);
    });
  });
  describe('extractFilterAndSorting', () => {
    it.each`
      search     | type        | sort     | orderBy  | result
      ${['one']} | ${'myType'} | ${'asc'} | ${'foo'} | ${{ sorting: { sort: 'asc', orderBy: 'foo' }, filters: [{ type: 'type', value: { data: 'myType' } }, { type: FILTERED_SEARCH_TERM, value: { data: 'one' } }] }}
      ${['one']} | ${null}     | ${'asc'} | ${'foo'} | ${{ sorting: { sort: 'asc', orderBy: 'foo' }, filters: [{ type: FILTERED_SEARCH_TERM, value: { data: 'one' } }] }}
      ${[]}      | ${null}     | ${'asc'} | ${'foo'} | ${{ sorting: { sort: 'asc', orderBy: 'foo' }, filters: [] }}
      ${null}    | ${null}     | ${'asc'} | ${'foo'} | ${{ sorting: { sort: 'asc', orderBy: 'foo' }, filters: [] }}
      ${null}    | ${null}     | ${null}  | ${'foo'} | ${{ sorting: { orderBy: 'foo' }, filters: [] }}
      ${null}    | ${null}     | ${null}  | ${null}  | ${{ sorting: {}, filters: [] }}
    `(
      'returns sorting and filters objects in the correct form',
      ({ search, type, sort, orderBy, result }) => {
        const queryObject = {
          search,
          type,
          sort,
          orderBy,
        };
        expect(extractFilterAndSorting(queryObject)).toStrictEqual(result);
      },
    );
  });
});
