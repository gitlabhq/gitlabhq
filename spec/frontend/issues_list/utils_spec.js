import { filteredTokens, locationSearch } from 'jest/issues_list/mock_data';
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
    expect(convertToApiParams(filteredTokens)).toEqual({
      author_username: 'homer',
      'not[author_username]': 'marge',
      assignee_username: 'bart',
      'not[assignee_username]': 'lisa',
      labels: 'cartoon,tv',
      'not[labels]': 'live action,drama',
    });
  });
});

describe('convertToUrlParams', () => {
  it('returns url params given filtered tokens', () => {
    expect(convertToUrlParams(filteredTokens)).toEqual({
      author_username: ['homer'],
      'not[author_username]': ['marge'],
      'assignee_username[]': ['bart'],
      'not[assignee_username][]': ['lisa'],
      'label_name[]': ['cartoon', 'tv'],
      'not[label_name][]': ['live action', 'drama'],
    });
  });
});

describe('convertToSearchQuery', () => {
  it('returns search string given filtered tokens', () => {
    expect(convertToSearchQuery(filteredTokens)).toBe('find issues');
  });
});
