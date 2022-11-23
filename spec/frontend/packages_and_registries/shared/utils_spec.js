import {
  getQueryParams,
  keyValueToFilterToken,
  searchArrayToFilterTokens,
  extractFilterAndSorting,
  beautifyPath,
  getCommitLink,
} from '~/packages_and_registries/shared/utils';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

import { packageList } from 'jest/packages_and_registries/infrastructure_registry/components/mock_data';

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

  describe('beautifyPath', () => {
    it('returns a string with spaces around /', () => {
      expect(beautifyPath('foo/bar')).toBe('foo / bar');
    });
    it('does not fail for empty string', () => {
      expect(beautifyPath()).toBe('');
    });
  });

  describe('getCommitLink', () => {
    it('returns a relative link when isGroup is false', () => {
      const link = getCommitLink(packageList[0], false);

      expect(link).toContain('../commit');
    });

    describe('when isGroup is true', () => {
      it('returns an absolute link matching project path', () => {
        const mavenPackage = packageList[0];
        const link = getCommitLink(mavenPackage, true);

        expect(link).toContain(`/${mavenPackage.project_path}/commit`);
      });
    });
  });
});
