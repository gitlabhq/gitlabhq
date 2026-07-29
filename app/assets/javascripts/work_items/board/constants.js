import { s__ } from '~/locale';

// Shared sortablejs group so cards can be dragged between every column.
export const BOARD_DND_GROUP = 'work-item-board';

// Class applied to each draggable card so the load-more row stays fixed.
export const BOARD_CARD_CLASS = 'js-board-card';

export const I18N_MOVE_ERROR = s__(
  'WorkItemBoard|Something went wrong while updating the work item. Please try again.',
);

// How long the drag lock must be held before we show a busy indicator for it,
// so brief moves don't cause a flash of greyed-out columns.
export const MOVE_IN_PROGRESS_INDICATOR_DELAY = 500;
