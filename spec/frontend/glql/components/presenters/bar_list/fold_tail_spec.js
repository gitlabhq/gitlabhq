import { foldSeries, foldTail } from '~/glql/components/presenters/bar_list/fold_tail';

describe('foldTail', () => {
  const toOther = (folded) => ({ name: `Other (${folded.length})`, folded });

  it('folds the items past the limit into one entry built from the tail', () => {
    const items = ['a', 'b', 'c', 'd', 'e'];

    expect(foldTail(items, 2, toOther)).toEqual([
      'a',
      'b',
      { name: 'Other (3)', folded: ['c', 'd', 'e'] },
    ]);
  });

  it('passes the folded tail to the builder in its original order', () => {
    const folded = foldTail(['a', 'b', 'c', 'd'], 1, toOther)[1];

    expect(folded.folded).toEqual(['b', 'c', 'd']);
  });

  it('keeps a lone item past the limit rather than folding it', () => {
    const items = ['a', 'b', 'c'];

    expect(foldTail(items, 2, toOther)).toBe(items);
  });

  it('returns the input untouched at or under the limit', () => {
    const items = ['a', 'b'];

    expect(foldTail(items, 2, toOther)).toBe(items);
    expect(foldTail(items, 3, toOther)).toBe(items);
  });

  it('returns an empty list untouched', () => {
    const items = [];

    expect(foldTail(items, 2, toOther)).toBe(items);
  });
});

describe('foldSeries', () => {
  const groups = ['u0', 'u1'];
  const bars = [
    { name: 'go', data: [1, 0] },
    { name: 'ruby', data: [12, 6] },
    { name: 'rust', data: [2, 0] },
  ];

  it('ranks series by total and sums the tail into Other per group', () => {
    expect(foldSeries({ bars, groups, max: 1 })).toEqual([
      { name: 'ruby', data: [12, 6] },
      { name: 'Other (2)', data: [3, 0] },
    ]);
  });

  it('gives a group with no folded values the missing value', () => {
    const sparse = [
      { name: 'ruby', data: [12, 6] },
      { name: 'go', data: [1, '-'] },
      { name: 'rust', data: [2, '-'] },
    ];

    expect(foldSeries({ bars: sparse, groups, max: 1, missingValue: '-' })[1]).toEqual({
      name: 'Other (2)',
      data: [3, '-'],
    });
  });
});
