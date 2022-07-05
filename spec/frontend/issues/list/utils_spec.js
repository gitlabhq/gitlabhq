import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import {
  apiParams,
  apiParamsWithSpecialValues,
  filteredTokens,
  filteredTokensWithSpecialValues,
  locationSearch,
  locationSearchWithSpecialValues,
  urlParams,
  urlParamsWithSpecialValues,
} from 'jest/issues/list/mock_data';
import { PAGE_SIZE, urlSortParams } from '~/issues/list/constants';
import {
  convertToApiParams,
  convertToSearchQuery,
  convertToUrlParams,
  getFilterTokens,
  getInitialPageParams,
  getSortKey,
  getSortOptions,
  isSortKey,
} from '~/issues/list/utils';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

describe('getInitialPageParams', () => {
  it('returns page params with a default page size when no arguments are given', () => {
    expect(getInitialPageParams()).toEqual({ firstPageSize: PAGE_SIZE });
  });

  it('returns page params with the given page size', () => {
    const pageSize = 100;
    expect(getInitialPageParams(pageSize)).toEqual({ firstPageSize: pageSize });
  });

  it('does not return firstPageSize when lastPageSize is provided', () => {
    const firstPageSize = 100;
    const lastPageSize = 50;
    const afterCursor = undefined;
    const beforeCursor = 'randomCursorString';
    const pageParams = getInitialPageParams(
      100,
      firstPageSize,
      lastPageSize,
      afterCursor,
      beforeCursor,
    );

    expect(pageParams).toEqual({ lastPageSize, beforeCursor });
  });
});

describe('getSortKey', () => {
  it.each(Object.keys(urlSortParams))('returns %s given the correct inputs', (sortKey) => {
    const sort = urlSortParams[sortKey];
    expect(getSortKey(sort)).toBe(sortKey);
  });
});

describe('isSortKey', () => {
  it.each(Object.keys(urlSortParams))('returns true given %s', (sort) => {
    expect(isSortKey(sort)).toBe(true);
  });

  it.each(['', 'asdf', null, undefined])('returns false given %s', (sort) => {
    expect(isSortKey(sort)).toBe(false);
  });
});

describe('getSortOptions', () => {
  describe.each`
    hasIssueWeightsFeature | hasBlockedIssuesFeature | length | containsWeight | containsBlocking
    ${false}               | ${false}                | ${10}  | ${false}       | ${false}
    ${true}                | ${false}                | ${11}  | ${true}        | ${false}
    ${false}               | ${true}                 | ${11}  | ${false}       | ${true}
    ${true}                | ${true}                 | ${12}  | ${true}        | ${true}
  `(
    'when hasIssueWeightsFeature=$hasIssueWeightsFeature and hasBlockedIssuesFeature=$hasBlockedIssuesFeature',
    ({
      hasIssueWeightsFeature,
      hasBlockedIssuesFeature,
      length,
      containsWeight,
      containsBlocking,
    }) => {
      const sortOptions = getSortOptions(hasIssueWeightsFeature, hasBlockedIssuesFeature);

      it('returns the correct length of sort options', () => {
        expect(sortOptions).toHaveLength(length);
      });

      it(`${containsWeight ? 'contains' : 'does not contain'} weight option`, () => {
        expect(sortOptions.some((option) => option.title === 'Weight')).toBe(containsWeight);
      });

      it(`${containsBlocking ? 'contains' : 'does not contain'} blocking option`, () => {
        expect(sortOptions.some((option) => option.title === 'Blocking')).toBe(containsBlocking);
      });
    },
  );
});

describe('getFilterTokens', () => {
  it('returns filtered tokens given "window.location.search"', () => {
    expect(getFilterTokens(locationSearch)).toEqual(filteredTokens);
  });

  it('returns filtered tokens given "window.location.search" with special values', () => {
    expect(getFilterTokens(locationSearchWithSpecialValues)).toEqual(
      filteredTokensWithSpecialValues,
    );
  });

  it.each`
    description              | argument
    ${'an undefined value'}  | ${undefined}
    ${'an irrelevant value'} | ${'?unrecognised=parameter'}
  `('returns an empty filtered search term given $description', ({ argument }) => {
    expect(getFilterTokens(argument)).toEqual([
      {
        id: expect.any(String),
        type: FILTERED_SEARCH_TERM,
        value: { data: '' },
      },
    ]);
  });
});

describe('convertToApiParams', () => {
  beforeEach(() => {
    setWindowLocation(TEST_HOST);
  });

  it('returns api params given filtered tokens', () => {
    expect(convertToApiParams(filteredTokens)).toEqual(apiParams);
  });

  it('returns api params given filtered tokens with special values', () => {
    setWindowLocation('?assignee_id=123');

    expect(convertToApiParams(filteredTokensWithSpecialValues)).toEqual(apiParamsWithSpecialValues);
  });
});

describe('convertToUrlParams', () => {
  beforeEach(() => {
    setWindowLocation(TEST_HOST);
  });

  it('returns url params given filtered tokens', () => {
    expect(convertToUrlParams(filteredTokens)).toEqual(urlParams);
  });

  it('returns url params given filtered tokens with special values', () => {
    setWindowLocation('?assignee_id=123');

    expect(convertToUrlParams(filteredTokensWithSpecialValues)).toEqual(urlParamsWithSpecialValues);
  });
});

describe('convertToSearchQuery', () => {
  it('returns search string given filtered tokens', () => {
    expect(convertToSearchQuery(filteredTokens)).toBe('find issues');
  });
});
