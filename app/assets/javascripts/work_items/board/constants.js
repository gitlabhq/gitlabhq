import { s__ } from '~/locale';

// Shared sortablejs group so cards can be dragged between every column.
export const BOARD_DND_GROUP = 'work-item-board';

// Class applied to each draggable card so the load-more row stays fixed.
export const BOARD_CARD_CLASS = 'js-board-card';

// Separate sortablejs group for column reordering, so columns and cards can
// never be dropped into each other's lists.
export const BOARD_COLUMN_DND_GROUP = 'work-item-board-columns';

// Class marking each draggable column, and the header grip you have to grab to
// start dragging it (so dragging a card inside the column doesn't move the column).
export const BOARD_COLUMN_CLASS = 'js-board-column';
export const BOARD_COLUMN_DRAG_HANDLE_CLASS = 'js-board-column-drag-handle';

// Header controls (like the column actions menu) that live inside the drag
// handle but shouldn't trigger a column drag when clicked.
export const BOARD_COLUMN_NO_DRAG_CLASS = 'js-board-column-no-drag';

export const I18N_MOVE_ERROR = s__(
  'WorkItemBoard|Something went wrong while updating the work item. Please try again.',
);

export const I18N_MOVE_SUCCESS = s__('WorkItemBoard|Moved %{reference} to %{targetGroup}');

// How long the drag lock must be held before we show a busy indicator for it,
// so brief moves don't cause a flash of greyed-out columns.
export const MOVE_IN_PROGRESS_INDICATOR_DELAY = 1000;
