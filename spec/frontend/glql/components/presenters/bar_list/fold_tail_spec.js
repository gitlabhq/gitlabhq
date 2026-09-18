import { foldTail } from '~/glql/components/presenters/bar_list/fold_tail';

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
