import { breakpoints } from '@gitlab/ui/dist/utils';

export const GRIDSTACK_MARGIN = 8;
export const GRIDSTACK_CSS_HANDLE = '.grid-stack-item-handle';

/* Magic number 125px:
 * After allowing for padding, and the panel title row, this leaves us with minimum 48px height for the cell content.
 * This means text/content with our spacing scale can fit up to 49px without scrolling.
 */
export const GRIDSTACK_CELL_HEIGHT = '125px';
export const GRIDSTACK_MIN_ROW = 1;

export const GRIDSTACK_BASE_CONFIG = {
  margin: GRIDSTACK_MARGIN,
  handle: GRIDSTACK_CSS_HANDLE,
  cellHeight: GRIDSTACK_CELL_HEIGHT,
  minRow: GRIDSTACK_MIN_ROW,
  columnOpts: { breakpoints: [{ w: breakpoints.md, c: 1 }] },
  alwaysShowResizeHandle: true,
  animate: true,
  float: true,
};

export const PANEL_POPOVER_DELAY = {
  hide: 500,
};

export const CURSOR_GRABBING_CLASS = '!gl-cursor-grabbing';
