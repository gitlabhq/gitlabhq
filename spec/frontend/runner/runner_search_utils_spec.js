import {
  searchValidator,
  updateOutdatedUrl,
  fromUrlQueryToSearch,
  fromSearchToUrl,
  fromSearchToVariables,
  isSearchFiltered,
} from 'ee_else_ce/runner/runner_search_utils';
import { mockSearchExamples } from './mock_data';

describe('search_params.js', () => {
  describe('searchValidator', () => {
    mockSearchExamples.forEach(({ name, search }) => {
      it(`Validates ${name} as a search object`, () => {
        expect(searchValidator(search)).toBe(true);
      });
    });
  });

  describe('updateOutdatedUrl', () => {
    it('returns null for urls that do not need updating', () => {
      expect(updateOutdatedUrl('http://test.host/')).toBe(null);
      expect(updateOutdatedUrl('http://test.host/?a=b')).toBe(null);
    });

    it.each`
      query                    | updatedQuery
      ${'status[]=ACTIVE'}     | ${'paused[]=false'}
      ${'status[]=ACTIVE&a=b'} | ${'a=b&paused[]=false'}
      ${'status[]=ACTIVE'}     | ${'paused[]=false'}
      ${'status[]=PAUSED'}     | ${'paused[]=true'}
    `('updates "$query" to "$updatedQuery"', ({ query, updatedQuery }) => {
      const mockUrl = 'http://test.host/admin/runners?';

      expect(updateOutdatedUrl(`${mockUrl}${query}`)).toBe(`${mockUrl}${updatedQuery}`);
    });
  });

  describe('fromUrlQueryToSearch', () => {
    mockSearchExamples.forEach(({ name, urlQuery, search }) => {
      it(`Converts ${name} to a search object`, () => {
        expect(fromUrlQueryToSearch(urlQuery)).toEqual(search);
      });
    });

    it('When search params appear as array, they are concatenated', () => {
      expect(fromUrlQueryToSearch('?search[]=my&search[]=text').filters).toEqual([
        { type: 'filtered-search-term', value: { data: 'my' } },
        { type: 'filtered-search-term', value: { data: 'text' } },
      ]);
    });

    it('When a page cannot be parsed as a number, it defaults to `1`', () => {
      expect(fromUrlQueryToSearch('?page=NONSENSE&after=AFTER_CURSOR').pagination).toEqual({
        page: 1,
      });
    });

    it('When a page is less than 1, it defaults to `1`', () => {
      expect(fromUrlQueryToSearch('?page=0&after=AFTER_CURSOR').pagination).toEqual({
        page: 1,
      });
    });

    it('When a page with no cursor is given, it defaults to `1`', () => {
      expect(fromUrlQueryToSearch('?page=2').pagination).toEqual({
        page: 1,
      });
    });
  });

  describe('fromSearchToUrl', () => {
    mockSearchExamples.forEach(({ name, urlQuery, search }) => {
      it(`Converts ${name} to a url`, () => {
        expect(fromSearchToUrl(search)).toBe(`http://test.host/${urlQuery}`);
      });
    });

    it.each([
      'http://test.host/?status[]=ACTIVE',
      'http://test.host/?runner_type[]=INSTANCE_TYPE',
      'http://test.host/?search=my_text',
    ])('When a filter is removed, it is removed from the URL', (initalUrl) => {
      const search = { filters: [], sort: 'CREATED_DESC' };
      const expectedUrl = `http://test.host/`;

      expect(fromSearchToUrl(search, initalUrl)).toBe(expectedUrl);
    });

    it('When unrelated search parameter is present, it does not get removed', () => {
      const initialUrl = `http://test.host/?unrelated=UNRELATED&status[]=ACTIVE`;
      const search = { filters: [], sort: 'CREATED_DESC' };
      const expectedUrl = `http://test.host/?unrelated=UNRELATED`;

      expect(fromSearchToUrl(search, initialUrl)).toBe(expectedUrl);
    });
  });

  describe('fromSearchToVariables', () => {
    mockSearchExamples.forEach(({ name, graphqlVariables, search }) => {
      it(`Converts ${name} to a GraphQL query variables object`, () => {
        expect(fromSearchToVariables(search)).toEqual(graphqlVariables);
      });
    });

    it('When a search param is empty, it gets removed', () => {
      expect(
        fromSearchToVariables({
          filters: [
            {
              type: 'filtered-search-term',
              value: { data: '' },
            },
          ],
        }),
      ).toMatchObject({
        search: '',
      });

      expect(
        fromSearchToVariables({
          filters: [
            {
              type: 'filtered-search-term',
              value: { data: 'something' },
            },
            {
              type: 'filtered-search-term',
              value: { data: '' },
            },
          ],
        }),
      ).toMatchObject({
        search: 'something',
      });
    });
  });

  describe('isSearchFiltered', () => {
    mockSearchExamples.forEach(({ name, search, isDefault }) => {
      it(`Given ${name}, evaluates to ${isDefault ? 'not ' : ''}filtered`, () => {
        expect(isSearchFiltered(search)).toBe(!isDefault);
      });
    });

    it('given a missing pagination, evaluates as not filtered', () => {
      expect(isSearchFiltered({ pagination: null })).toBe(false);
    });
  });
});
