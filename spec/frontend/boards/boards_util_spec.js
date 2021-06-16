import { filterVariables } from '~/boards/boards_util';

describe('filterVariables', () => {
  it.each([
    [
      'correctly processes array filter values',
      {
        filters: {
          'not[filterA]': ['val1', 'val2'],
        },
        expected: {
          not: {
            filterA: ['val1', 'val2'],
          },
        },
      },
    ],
    [
      "renames a filter if 'remap' method is available",
      {
        filters: {
          filterD: 'some value',
        },
        expected: {
          filterA: 'some value',
          not: {},
        },
      },
    ],
    [
      'correctly processes a negated filter that supports negation',
      {
        filters: {
          'not[filterA]': 'some value 1',
          'not[filterB]': 'some value 2',
        },
        expected: {
          not: {
            filterA: 'some value 1',
          },
        },
      },
    ],
    [
      'correctly removes an unsupported filter depending on issuableType',
      {
        issuableType: 'epic',
        filters: {
          filterA: 'some value 1',
          filterE: 'some value 2',
        },
        expected: {
          filterE: 'some value 2',
          not: {},
        },
      },
    ],
    [
      'applies a transform when the filter value needs to be modified',
      {
        filters: {
          filterC: 'abc',
          'not[filterC]': 'def',
        },
        expected: {
          filterC: 'ABC',
          not: {
            filterC: 'DEF',
          },
        },
      },
    ],
  ])('%s', (_, { filters, issuableType = 'issue', expected }) => {
    const result = filterVariables({
      filters,
      issuableType,
      filterInfo: {
        filterA: {
          negatedSupport: true,
        },
        filterB: {
          negatedSupport: false,
        },
        filterC: {
          negatedSupport: true,
          transform: (val) => val.toUpperCase(),
        },
        filterD: {
          remap: () => 'filterA',
        },
        filterE: {
          negatedSupport: true,
        },
      },
      filterFields: {
        issue: ['filterA', 'filterB', 'filterC', 'filterD'],
        epic: ['filterE'],
      },
    });

    expect(result).toEqual(expected);
  });
});
