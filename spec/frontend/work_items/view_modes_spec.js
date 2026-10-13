import { hasBoardViewMode, viewModeOptions } from '~/work_items/view_modes';
import { VIEW_MODE_BOARD, VIEW_MODE_LIST, VIEW_MODE_TABLE } from '~/work_items/constants';

describe('view modes', () => {
  it('offers the list and table view modes', () => {
    expect(viewModeOptions.map(({ value }) => value)).toEqual([VIEW_MODE_LIST, VIEW_MODE_TABLE]);
  });

  // A board's columns can only group by status, which is EE-only.
  it('does not offer the board view mode', () => {
    expect(viewModeOptions.some(({ value }) => value === VIEW_MODE_BOARD)).toBe(false);
    expect(hasBoardViewMode).toBe(false);
  });
});
