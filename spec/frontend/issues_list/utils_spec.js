import { apiParams, filteredTokens, locationSearch, urlParams } from 'jest/issues_list/mock_data';
import { sortParams } from '~/issues_list/constants';
import {
  convertToApiParams,
  convertToSearchQuery,
  convertToUrlParams,
  getFilterTokens,
  getSortKey,
} from '~/issues_list/utils';

describe('getSortKey', () => {
  it.each(Object.keys(sortParams))('returns %s given the correct inputs', (sortKey) => {
    const { order_by, sort } = sortParams[sortKey];
    expect(getSortKey(order_by, sort)).toBe(sortKey);
  });
});

describe('getFilterTokens', () => {
  it('returns filtered tokens given "window.location.search"', () => {
    expect(getFilterTokens(locationSearch)).toEqual(filteredTokens);
  });
});

describe('convertToApiParams', () => {
  it('returns api params given filtered tokens', () => {
    expect(convertToApiParams(filteredTokens)).toEqual(apiParams);
  });
});

describe('convertToUrlParams', () => {
  it('returns url params given filtered tokens', () => {
    expect(convertToUrlParams(filteredTokens)).toEqual(urlParams);
  });
});

describe('convertToSearchQuery', () => {
  it('returns search string given filtered tokens', () => {
    expect(convertToSearchQuery(filteredTokens)).toBe('find issues');
  });
});
