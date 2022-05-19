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
import {
  PAGE_SIZE,
  PAGE_SIZE_MANUAL,
  RELATIVE_POSITION_ASC,
  urlSortParams,
} from '~/issues/list/constants';
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

describe('getInitialPageParams', () => {
  it.each(Object.keys(urlSortParams))(
    'returns the correct page params for sort key %s',
    (sortKey) => {
      const firstPageSize = sortKey === RELATIVE_POSITION_ASC ? PAGE_SIZE_MANUAL : PAGE_SIZE;

      expect(getInitialPageParams(sortKey)).toEqual({ firstPageSize });
    },
  );

  it.each(Object.keys(urlSortParams))(
    'returns the correct page params for sort key %s with afterCursor',
    (sortKey) => {
      const firstPageSize = sortKey === RELATIVE_POSITION_ASC ? PAGE_SIZE_MANUAL : PAGE_SIZE;
      const afterCursor = 'randomCursorString';
      const beforeCursor = undefined;

      expect(getInitialPageParams(sortKey, afterCursor, beforeCursor)).toEqual({
        firstPageSize,
        afterCursor,
      });
    },
  );

  it.each(Object.keys(urlSortParams))(
    'returns the correct page params for sort key %s with beforeCursor',
    (sortKey) => {
      const firstPageSize = sortKey === RELATIVE_POSITION_ASC ? PAGE_SIZE_MANUAL : PAGE_SIZE;
      const afterCursor = undefined;
      const beforeCursor = 'anotherRandomCursorString';

      expect(getInitialPageParams(sortKey, afterCursor, beforeCursor)).toEqual({
        firstPageSize,
        beforeCursor,
      });
    },
  );
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
    ${false}               | ${false}                | ${9}   | ${false}       | ${false}
    ${true}                | ${false}                | ${10}  | ${true}        | ${false}
    ${false}               | ${true}                 | ${10}  | ${false}       | ${true}
    ${true}                | ${true}                 | ${11}  | ${true}        | ${true}
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
