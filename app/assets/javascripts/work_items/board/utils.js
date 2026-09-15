import { omit } from 'lodash-es';
import getBoardWorkItemsQuery from 'ee_else_ce/work_items/board/graphql/get_board_work_items.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';
import { DEFAULT_PAGE_SIZE_BOARD_COLUMN } from '~/work_items/constants';

const LIST_PAGINATION_VARIABLES = ['afterCursor', 'beforeCursor', 'lastPageSize'];

// Board columns and the drag-and-drop cache updates have to use this exact
// same query, so they read and write the same Apollo cache entry.
export const boardColumnQuery = (glFeatures) =>
  glFeatures.workItemRestApiFrontendUsers ? getWorkItemsRestQuery : getBoardWorkItemsQuery;

// Variables for the first, non-paginated page. `fetchMore` merges later pages
// into whatever cache entry these variables point to, so the drag-and-drop
// cache updates have to build the exact same variables to land on that entry.
// The grouping strategy supplies `groupFilter` (e.g. `{ status: { name } }`),
// so this stays agnostic to which attribute the board is grouped by.
export const boardColumnQueryVariables = ({
  rootPageFullPath,
  baseQueryVariables,
  groupFilter,
}) => ({
  fullPath: rootPageFullPath,
  ...omit(baseQueryVariables, LIST_PAGINATION_VARIABLES),
  firstPageSize: DEFAULT_PAGE_SIZE_BOARD_COLUMN,
  ...groupFilter, // spread last, so it wins if a base variable uses the same key
});

// The count query is a separate query document, so it lives in its own cache
// entry (card moves don't touch it). It doesn't accept `firstPageSize`, so we
// strip that out. board_view uses these same variables to key its count updates.
export const boardColumnCountVariables = (params) => {
  const { firstPageSize, ...countVariables } = boardColumnQueryVariables(params);
  return countVariables;
};

// Works out the moveBeforeId/moveAfterId for a card move, based on the target
// column's order before the move (`nodes`). For a same-column move, source and
// target are the same list. This mirrors the neighbour logic in
// boards/components/board_list.vue so both boards order items the same way.
// IDs are full GraphQL global ids — the workItemUpdate mutation parses them server-side.
export const getMovePositionIds = ({ nodes = [], sameColumn, oldIndex, newIndex }) => {
  const idAt = (index) => nodes[index]?.id;

  if (sameColumn) {
    // Moved down: the card that was at the drop index now sits before the moved card.
    if (newIndex > oldIndex) {
      return { moveBeforeId: idAt(newIndex) };
    }
    // Moved up: the card that was at the drop index now sits after the moved card.
    if (newIndex < oldIndex) {
      return { moveAfterId: idAt(newIndex) };
    }
    // Dropped back where it started — nothing to reorder.
    return {};
  }

  // Cross-column: the card lands at newIndex, so its new neighbours are
  // whatever currently sits either side of that slot.
  return { moveBeforeId: idAt(newIndex - 1), moveAfterId: idAt(newIndex) };
};
