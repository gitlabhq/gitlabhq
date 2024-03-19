import {
  searchValidator,
  updateOutdatedUrl,
  fromUrlQueryToSearch,
  fromSearchToUrl,
  fromSearchToVariables,
  isSearchFiltered,
} from 'ee_else_ce/ci/runner/runner_search_utils';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import { DEFAULT_SORT } from '~/ci/runner/constants';
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
      query                                   | updatedQuery
      ${'status[]=ACTIVE'}                    | ${'paused[]=false'}
      ${'status[]=ACTIVE&a=b'}                | ${'a=b&paused[]=false'}
      ${'status[]=ACTIVE'}                    | ${'paused[]=false'}
      ${'status[]=PAUSED'}                    | ${'paused[]=true'}
      ${'page=2&after=AFTER'}                 | ${'after=AFTER'}
      ${'page=2&before=BEFORE'}               | ${'before=BEFORE'}
      ${'status[]=PAUSED&page=2&after=AFTER'} | ${'after=AFTER&paused[]=true'}
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
        { type: FILTERED_SEARCH_TERM, value: { data: 'my text' } },
      ]);
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
      'http://test.host/?paused[]=true',
      'http://test.host/?search=my_text',
      'http://test.host/?creator[]=root',
    ])('When a filter is removed, it is removed from the URL', (initialUrl) => {
      const search = { filters: [], sort: DEFAULT_SORT };
      const expectedUrl = `http://test.host/`;

      expect(fromSearchToUrl(search, initialUrl)).toBe(expectedUrl);
    });

    it('When unrelated search parameter is present, it does not get removed', () => {
      const initialUrl = `http://test.host/?unrelated=UNRELATED&status[]=ACTIVE`;
      const search = { filters: [], sort: DEFAULT_SORT };
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
              type: FILTERED_SEARCH_TERM,
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
              type: FILTERED_SEARCH_TERM,
              value: { data: 'something' },
            },
            {
              type: FILTERED_SEARCH_TERM,
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

    it.each([null, undefined, {}])(
      'given a missing pagination, evaluates as not filtered',
      (mockPagination) => {
        expect(isSearchFiltered({ pagination: mockPagination })).toBe(false);
      },
    );
  });
});
