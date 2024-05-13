import { useLocalStorageSpy } from 'helpers/local_storage_helper';

import AccessorUtilities from '~/lib/utils/accessor';

import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

import {
  uniqueTokens,
  prepareTokens,
  processFilters,
  filterToQueryObject,
  urlQueryToFilter,
  getRecentlyUsedSuggestions,
  setTokenValueToRecentlyUsed,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';

import {
  tokenValueAuthor,
  tokenValueLabel,
  tokenValueMilestone,
  tokenValuePlain,
} from './mock_data';

const mockStorageKey = 'recent-tokens';

function setLocalStorageAvailability(isAvailable) {
  jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(isAvailable);
}

describe('Filtered Search Utils', () => {
  describe('uniqueTokens', () => {
    it('returns tokens array with duplicates removed', () => {
      expect(
        uniqueTokens([
          tokenValueAuthor,
          tokenValueLabel,
          tokenValueMilestone,
          tokenValueLabel,
          tokenValuePlain,
        ]),
      ).toHaveLength(4); // Removes 2nd instance of tokenValueLabel
    });

    it('returns tokens array as it is if it does not have duplicates', () => {
      expect(
        uniqueTokens([tokenValueAuthor, tokenValueLabel, tokenValueMilestone, tokenValuePlain]),
      ).toHaveLength(4);
    });
  });
});

describe('prepareTokens', () => {
  describe('with empty data', () => {
    it('returns an empty array', () => {
      expect(prepareTokens()).toEqual([]);
      expect(prepareTokens({})).toEqual([]);
      expect(prepareTokens({ milestone: null, author: null, assignees: [], labels: [] })).toEqual(
        [],
      );
    });
  });

  it.each([
    [
      'milestone',
      { value: 'v1.0', operator: '=' },
      [{ type: 'milestone', value: { data: 'v1.0', operator: '=' } }],
    ],
    [
      'author',
      { value: 'mr.popo', operator: '!=' },
      [{ type: 'author', value: { data: 'mr.popo', operator: '!=' } }],
    ],
    [
      'labels',
      [{ value: 'z-fighters', operator: '=' }],
      [{ type: 'labels', value: { data: 'z-fighters', operator: '=' } }],
    ],
    [
      'assignees',
      [
        { value: 'krillin', operator: '=' },
        { value: 'piccolo', operator: '!=' },
      ],
      [
        { type: 'assignees', value: { data: 'krillin', operator: '=' } },
        { type: 'assignees', value: { data: 'piccolo', operator: '!=' } },
      ],
    ],
    [
      'foo',
      [
        { value: 'bar', operator: '!=' },
        { value: 'baz', operator: '!=' },
      ],
      [
        { type: 'foo', value: { data: 'bar', operator: '!=' } },
        { type: 'foo', value: { data: 'baz', operator: '!=' } },
      ],
    ],
  ])('gathers %s=%j into result=%j', (token, value, result) => {
    const res = prepareTokens({ [token]: value });
    expect(res).toEqual(result);
  });
});

describe('processFilters', () => {
  it('processes multiple filter values', () => {
    const result = processFilters([
      { type: 'foo', value: { data: 'foo', operator: '=' } },
      { type: 'bar', value: { data: 'bar1', operator: '=' } },
      { type: 'bar', value: { data: 'bar2', operator: '!=' } },
      'just a string',
      'and another',
    ]);

    expect(result).toStrictEqual({
      foo: [{ value: 'foo', operator: '=' }],
      bar: [
        { value: 'bar1', operator: '=' },
        { value: 'bar2', operator: '!=' },
      ],
      'filtered-search-term': [
        { value: 'just a string', operator: undefined },
        { value: 'and another', operator: undefined },
      ],
    });
  });

  it('does not remove wrapping double quotes from the data', () => {
    const result = processFilters([
      { type: 'foo', value: { data: '"value with spaces"', operator: '=' } },
    ]);

    expect(result).toStrictEqual({
      foo: [{ value: '"value with spaces"', operator: '=' }],
    });
  });
});

describe('filterToQueryObject', () => {
  describe('with empty data', () => {
    it('returns an empty object', () => {
      expect(filterToQueryObject()).toEqual({});
      expect(filterToQueryObject({})).toEqual({});
      expect(filterToQueryObject({ author_username: null, label_name: [] })).toEqual({
        author_username: null,
        label_name: null,
        'not[author_username]': null,
        'not[label_name]': null,
      });
    });
  });

  it.each([
    [
      'author_username',
      { value: 'v1.0', operator: '=' },
      { author_username: 'v1.0', 'not[author_username]': null },
    ],
    [
      'author_username',
      { value: 'v1.0', operator: '!=' },
      { author_username: null, 'not[author_username]': 'v1.0' },
    ],
    [
      'label_name',
      [{ value: 'z-fighters', operator: '=' }],
      { label_name: ['z-fighters'], 'not[label_name]': null },
    ],
    [
      'label_name',
      [{ value: 'z-fighters', operator: '!=' }],
      { label_name: null, 'not[label_name]': ['z-fighters'] },
    ],
    [
      'foo',
      [
        { value: 'bar', operator: '=' },
        { value: 'baz', operator: '=' },
      ],
      { foo: ['bar', 'baz'], 'not[foo]': null },
    ],
    [
      'foo',
      [
        { value: 'bar', operator: '!=' },
        { value: 'baz', operator: '!=' },
      ],
      { foo: null, 'not[foo]': ['bar', 'baz'] },
    ],
    [
      'foo',
      [
        { value: 'bar', operator: '!=' },
        { value: 'baz', operator: '=' },
      ],
      { foo: ['baz'], 'not[foo]': ['bar'] },
    ],
  ])('gathers filter values %s=%j into query object=%j', (token, value, result) => {
    const res = filterToQueryObject({ [token]: value });
    expect(res).toEqual(result);
  });

  it.each([
    [FILTERED_SEARCH_TERM, [{ value: '' }], { search: '' }],
    [FILTERED_SEARCH_TERM, [{ value: 'bar' }], { search: 'bar' }],
    [FILTERED_SEARCH_TERM, [{ value: 'bar' }, { value: '' }], { search: 'bar' }],
    [FILTERED_SEARCH_TERM, [{ value: 'bar' }, { value: 'baz' }], { search: 'bar baz' }],
  ])(
    'when filteredSearchTermKey=search gathers filter values %s=%j into query object=%j',
    (token, value, result) => {
      const res = filterToQueryObject({ [token]: value }, { filteredSearchTermKey: 'search' });
      expect(res).toEqual(result);
    },
  );

  describe('with custom operators', () => {
    it('does not handle filters without custom operators', () => {
      const res = filterToQueryObject({
        foo: [
          { value: '100', operator: '>' },
          { value: '200', operator: '<' },
        ],
      });
      expect(res).toEqual({ foo: null, 'not[foo]': null });
    });

    it('handles filters with custom operators', () => {
      const res = filterToQueryObject(
        {
          foo: [
            { value: '100', operator: '>' },
            { value: '200', operator: '<' },
          ],
        },
        {
          customOperators: [
            {
              operator: '>',
              prefix: 'gt',
            },
            {
              operator: '<',
              prefix: 'lt',
            },
          ],
        },
      );
      expect(res).toEqual({ foo: null, 'gt[foo]': ['100'], 'lt[foo]': ['200'], 'not[foo]': null });
    });
  });

  it('when applyOnlyToKey is present, it only process custom operators for the given key', () => {
    const res = filterToQueryObject(
      {
        foo: [{ value: '100', operator: '>' }],
        bar: [{ value: '100', operator: '>' }],
      },
      {
        customOperators: [
          {
            operator: '>',
            prefix: 'gt',
            applyOnlyToKey: 'foo',
          },
        ],
      },
    );
    expect(res).toEqual({
      bar: null,
      'not[bar]': null,
      foo: null,
      'gt[foo]': ['100'],
      'not[foo]': null,
    });
  });

  describe('when `shouldExcludeEmpty` is set to `true`', () => {
    it('excludes empty filters', () => {
      expect(
        filterToQueryObject(
          {
            language: [
              {
                value: '5',
                operator: '=',
              },
            ],
            FILTERED_SEARCH_TERM: [
              {
                value: '',
              },
            ],
            fooBar: [
              {
                value: '',
                operator: '=',
              },
            ],
          },
          { shouldExcludeEmpty: true },
        ),
      ).toEqual({ language: ['5'] });
    });
  });
});

describe('urlQueryToFilter', () => {
  describe('with empty data', () => {
    it('returns an empty object', () => {
      expect(urlQueryToFilter()).toEqual({});
      expect(urlQueryToFilter('')).toEqual({});
      expect(urlQueryToFilter('author_username=&milestone_title=&')).toEqual({});
    });
  });

  it.each([
    ['author_username=v1.0', { author_username: { value: 'v1.0', operator: '=' } }],
    ['not[author_username]=v1.0', { author_username: { value: 'v1.0', operator: '!=' } }],
    ['foo=bar&foo=baz', { foo: { value: 'baz', operator: '=' } }],
    ['foo=bar&foo[]=baz', { foo: [{ value: 'baz', operator: '=' }] }],
    ['not[foo]=bar&foo=baz', { foo: { value: 'baz', operator: '=' } }],
    [
      'foo[]=bar&foo[]=baz&not[foo]=',
      {
        foo: [
          { value: 'bar', operator: '=' },
          { value: 'baz', operator: '=' },
        ],
      },
    ],
    [
      'foo[]=&not[foo][]=bar&not[foo][]=baz',
      {
        foo: [
          { value: 'bar', operator: '!=' },
          { value: 'baz', operator: '!=' },
        ],
      },
    ],
    [
      'foo[]=baz&not[foo][]=bar',
      {
        foo: [
          { value: 'baz', operator: '=' },
          { value: 'bar', operator: '!=' },
        ],
      },
    ],
    ['not[foo][]=bar', { foo: [{ value: 'bar', operator: '!=' }] }],
    ['nop=1&not[nop]=2', {}, { filterNamesAllowList: ['foo'] }],
    [
      'foo[]=bar&not[foo][]=baz&nop=xxx&not[nop]=yyy',
      {
        foo: [
          { value: 'bar', operator: '=' },
          { value: 'baz', operator: '!=' },
        ],
      },
      { filterNamesAllowList: ['foo'] },
    ],
    [
      'search=term&foo=bar',
      {
        [FILTERED_SEARCH_TERM]: [{ value: 'term' }],
        foo: { value: 'bar', operator: '=' },
      },
      { filteredSearchTermKey: 'search' },
    ],
    [
      'search=my terms',
      {
        [FILTERED_SEARCH_TERM]: [{ value: 'my terms' }],
      },
      { filteredSearchTermKey: 'search' },
    ],
    [
      'search[]=my&search[]=terms',
      {
        [FILTERED_SEARCH_TERM]: [{ value: 'my terms' }],
      },
      { filteredSearchTermKey: 'search' },
    ],
    [
      'search=my+terms',
      {
        [FILTERED_SEARCH_TERM]: [{ value: 'my terms' }],
      },
      { filteredSearchTermKey: 'search' },
    ],
    [
      'search=my terms&foo=bar&nop=xxx',
      {
        [FILTERED_SEARCH_TERM]: [{ value: 'my terms' }],
        foo: { value: 'bar', operator: '=' },
      },
      { filteredSearchTermKey: 'search', filterNamesAllowList: ['foo'] },
    ],
    [
      {
        search: 'my terms',
        foo: 'bar',
        nop: 'xxx',
      },
      {
        [FILTERED_SEARCH_TERM]: [{ value: 'my terms' }],
        foo: { value: 'bar', operator: '=' },
      },
      { filteredSearchTermKey: 'search', filterNamesAllowList: ['foo'] },
    ],
  ])(
    'gathers filter values %s into query object=%j when options %j',
    (query, result, options = undefined) => {
      const res = urlQueryToFilter(query, options);
      expect(res).toEqual(result);
    },
  );

  describe('custom operators', () => {
    it('handles query param with custom operators', () => {
      const res = urlQueryToFilter('gt[foo]=bar', {
        customOperators: [{ operator: '>', prefix: 'gt' }],
      });
      expect(res).toEqual({ foo: { operator: '>', value: 'bar' } });
    });

    it('does not handle query param without custom operators', () => {
      const res = urlQueryToFilter('gt[foo]=bar');
      expect(res).toEqual({ 'gt[foo]': { operator: '=', value: 'bar' } });
    });
  });
});

describe('getRecentlyUsedSuggestions', () => {
  useLocalStorageSpy();

  beforeEach(() => {
    localStorage.removeItem(mockStorageKey);
  });

  it('returns array containing recently used token values from provided recentSuggestionsStorageKey', () => {
    setLocalStorageAvailability(true);

    const mockExpectedArray = [{ foo: 'bar' }];
    localStorage.setItem(mockStorageKey, JSON.stringify(mockExpectedArray));

    expect(getRecentlyUsedSuggestions(mockStorageKey)).toEqual(mockExpectedArray);
  });

  it('returns empty array when provided recentSuggestionsStorageKey does not have anything in localStorage', () => {
    setLocalStorageAvailability(true);

    expect(getRecentlyUsedSuggestions(mockStorageKey)).toEqual([]);
  });

  it('returns empty array when when access to localStorage is not available', () => {
    setLocalStorageAvailability(false);

    expect(getRecentlyUsedSuggestions(mockStorageKey)).toEqual([]);
  });
});

describe('setTokenValueToRecentlyUsed', () => {
  const mockTokenValue1 = { foo: 'bar' };
  const mockTokenValue2 = { bar: 'baz' };
  useLocalStorageSpy();

  beforeEach(() => {
    localStorage.removeItem(mockStorageKey);
  });

  it('adds provided tokenValue to localStorage for recentSuggestionsStorageKey', () => {
    setLocalStorageAvailability(true);

    setTokenValueToRecentlyUsed(mockStorageKey, mockTokenValue1);

    expect(JSON.parse(localStorage.getItem(mockStorageKey))).toEqual([mockTokenValue1]);
  });

  it('adds provided tokenValue to localStorage at the top of existing values (i.e. Stack order)', () => {
    setLocalStorageAvailability(true);

    setTokenValueToRecentlyUsed(mockStorageKey, mockTokenValue1);
    setTokenValueToRecentlyUsed(mockStorageKey, mockTokenValue2);

    expect(JSON.parse(localStorage.getItem(mockStorageKey))).toEqual([
      mockTokenValue2,
      mockTokenValue1,
    ]);
  });

  it('ensures that provided tokenValue is not added twice', () => {
    setLocalStorageAvailability(true);

    setTokenValueToRecentlyUsed(mockStorageKey, mockTokenValue1);
    setTokenValueToRecentlyUsed(mockStorageKey, mockTokenValue1);

    expect(JSON.parse(localStorage.getItem(mockStorageKey))).toEqual([mockTokenValue1]);
  });

  it('does not add any value when acess to localStorage is not available', () => {
    setLocalStorageAvailability(false);

    setTokenValueToRecentlyUsed(mockStorageKey, mockTokenValue1);

    expect(JSON.parse(localStorage.getItem(mockStorageKey))).toBeNull();
  });
});
