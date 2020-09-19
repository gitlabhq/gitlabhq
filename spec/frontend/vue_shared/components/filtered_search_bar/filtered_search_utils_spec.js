import {
  stripQuotes,
  uniqueTokens,
  prepareTokens,
  processFilters,
  filterToQueryObject,
  urlQueryToFilter,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';

import {
  tokenValueAuthor,
  tokenValueLabel,
  tokenValueMilestone,
  tokenValuePlain,
} from './mock_data';

describe('Filtered Search Utils', () => {
  describe('stripQuotes', () => {
    it.each`
      inputValue     | outputValue
      ${'"Foo Bar"'} | ${'Foo Bar'}
      ${"'Foo Bar'"} | ${'Foo Bar'}
      ${'FooBar'}    | ${'FooBar'}
      ${"Foo'Bar"}   | ${"Foo'Bar"}
      ${'Foo"Bar'}   | ${'Foo"Bar'}
      ${'Foo Bar'}   | ${'Foo Bar'}
    `(
      'returns string $outputValue when called with string $inputValue',
      ({ inputValue, outputValue }) => {
        expect(stripQuotes(inputValue)).toBe(outputValue);
      },
    );
  });

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
      [{ value: 'krillin', operator: '=' }, { value: 'piccolo', operator: '!=' }],
      [
        { type: 'assignees', value: { data: 'krillin', operator: '=' } },
        { type: 'assignees', value: { data: 'piccolo', operator: '!=' } },
      ],
    ],
    [
      'foo',
      [{ value: 'bar', operator: '!=' }, { value: 'baz', operator: '!=' }],
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
    ]);

    expect(result).toStrictEqual({
      foo: [{ value: 'foo', operator: '=' }],
      bar: [{ value: 'bar1', operator: '=' }, { value: 'bar2', operator: '!=' }],
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
      [{ value: 'bar', operator: '=' }, { value: 'baz', operator: '=' }],
      { foo: ['bar', 'baz'], 'not[foo]': null },
    ],
    [
      'foo',
      [{ value: 'bar', operator: '!=' }, { value: 'baz', operator: '!=' }],
      { foo: null, 'not[foo]': ['bar', 'baz'] },
    ],
    [
      'foo',
      [{ value: 'bar', operator: '!=' }, { value: 'baz', operator: '=' }],
      { foo: ['baz'], 'not[foo]': ['bar'] },
    ],
  ])('gathers filter values %s=%j into query object=%j', (token, value, result) => {
    const res = filterToQueryObject({ [token]: value });
    expect(res).toEqual(result);
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
      { foo: [{ value: 'bar', operator: '=' }, { value: 'baz', operator: '=' }] },
    ],
    [
      'foo[]=&not[foo][]=bar&not[foo][]=baz',
      { foo: [{ value: 'bar', operator: '!=' }, { value: 'baz', operator: '!=' }] },
    ],
    [
      'foo[]=baz&not[foo][]=bar',
      { foo: [{ value: 'baz', operator: '=' }, { value: 'bar', operator: '!=' }] },
    ],
    ['not[foo][]=bar', { foo: [{ value: 'bar', operator: '!=' }] }],
  ])('gathers filter values %s into query object=%j', (query, result) => {
    const res = urlQueryToFilter(query);
    expect(res).toEqual(result);
  });
});
