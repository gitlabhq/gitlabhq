import { groupingStrategyFor } from '~/work_items/board/grouping';

describe('groupingStrategyFor', () => {
  // 'status' resolves to a strategy in both editions (placeholder in CE, real
  // strategy in EE), so the only case actually worth testing here is the unsupported one.
  it('returns null for an unsupported property', () => {
    expect(groupingStrategyFor('assignee')).toBe(null);
  });
});
