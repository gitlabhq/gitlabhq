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
import { urlSortParams } from '~/issues/list/constants';
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
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';

describe('getInitialPageParams', () => {
  it('returns page params with a default page size when no arguments are given', () => {
    expect(getInitialPageParams()).toEqual({ firstPageSize: DEFAULT_PAGE_SIZE });
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
    hasIssuableHealthStatusFeature | hasIssueWeightsFeature | hasBlockedIssuesFeature | length | containsHealthStatus | containsWeight | containsBlocking
    ${false}                       | ${false}               | ${false}                | ${10}  | ${false}             | ${false}       | ${false}
    ${false}                       | ${false}               | ${true}                 | ${11}  | ${false}             | ${false}       | ${true}
    ${false}                       | ${true}                | ${false}                | ${11}  | ${false}             | ${true}        | ${false}
    ${false}                       | ${true}                | ${true}                 | ${12}  | ${false}             | ${true}        | ${true}
    ${true}                        | ${false}               | ${false}                | ${11}  | ${true}              | ${false}       | ${false}
    ${true}                        | ${false}               | ${true}                 | ${12}  | ${true}              | ${false}       | ${true}
    ${true}                        | ${true}                | ${false}                | ${12}  | ${true}              | ${true}        | ${false}
    ${true}                        | ${true}                | ${true}                 | ${13}  | ${true}              | ${true}        | ${true}
  `(
    'when hasIssuableHealthStatusFeature=$hasIssuableHealthStatusFeature, hasIssueWeightsFeature=$hasIssueWeightsFeature and hasBlockedIssuesFeature=$hasBlockedIssuesFeature',
    ({
      hasIssuableHealthStatusFeature,
      hasIssueWeightsFeature,
      hasBlockedIssuesFeature,
      length,
      containsHealthStatus,
      containsWeight,
      containsBlocking,
    }) => {
      const sortOptions = getSortOptions({
        hasBlockedIssuesFeature,
        hasIssuableHealthStatusFeature,
        hasIssueWeightsFeature,
      });

      it('returns the correct length of sort options', () => {
        expect(sortOptions).toHaveLength(length);
      });

      it(`${containsHealthStatus ? 'contains' : 'does not contain'} health status option`, () => {
        expect(sortOptions.some((option) => option.title === 'Health')).toBe(containsHealthStatus);
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
