import { groupingStrategyFor } from '~/work_items/board/grouping';

describe('groupingStrategyFor', () => {
  // The 'status' property resolves to a strategy in both editions (a placeholder
  // in CE, the real strategy in EE), so this only covers the invariant case.
  it('returns null for an unsupported property', () => {
    expect(groupingStrategyFor('assignee')).toBe(null);
  });
});
