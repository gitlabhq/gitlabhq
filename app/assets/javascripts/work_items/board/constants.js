import { s__ } from '~/locale';

// Shared sortablejs group so cards can be dragged between every column.
export const BOARD_DND_GROUP = 'work-item-board';

// Class applied to each draggable card so the load-more row stays fixed.
export const BOARD_CARD_CLASS = 'js-board-card';

// Separate sortablejs group for column reordering so columns and cards never
// interact (a card can't be dropped into the column strip, or vice versa).
export const BOARD_COLUMN_DND_GROUP = 'work-item-board-columns';

// Class marking each draggable column, and the header grip that must be grabbed
// to start a column drag (so dragging a card inside a column doesn't move it).
export const BOARD_COLUMN_CLASS = 'js-board-column';
export const BOARD_COLUMN_DRAG_HANDLE_CLASS = 'js-board-column-drag-handle';

// Interactive header controls (e.g. the column actions menu) that must not start
// a column drag even though they live inside the drag handle.
export const BOARD_COLUMN_NO_DRAG_CLASS = 'js-board-column-no-drag';

export const I18N_MOVE_ERROR = s__(
  'WorkItemBoard|Something went wrong while updating the work item. Please try again.',
);

export const I18N_MOVE_SUCCESS = s__('WorkItemBoard|Moved %{reference} to %{targetGroup}');

// How long the drag lock must be held before we show a busy indicator for it,
// so brief moves don't cause a flash of greyed-out columns.
export const MOVE_IN_PROGRESS_INDICATOR_DELAY = 1000;
