import getBoardWorkItemsQuery from 'ee_else_ce/work_items/board/graphql/get_board_work_items.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';
import { DEFAULT_PAGE_SIZE_BOARD_COLUMN } from '~/work_items/constants';

// Board columns and the drag-and-drop cache updates have to use this exact
// same query, so they read and write the same Apollo cache entry.
export const boardColumnQuery = (glFeatures) =>
  glFeatures.workItemRestApiFrontendUsers ? getWorkItemsRestQuery : getBoardWorkItemsQuery;

// These group-identity helpers talk about "groups" rather than "columns"
// because board columns are just one view built on top of grouping.

// Placeholder id for the "no value" group, for groupings that have one (like
// "No label" or "Unassigned"). Status always has a value, so there's no
// "No status" group — GROUP_NONE just gives every grouping a consistent way
// to represent "this item has nothing for this attribute".
export const GROUP_NONE = 'none';

// Identifies which grouping dimension a group belongs to. Adds a sub-key when
// the dimension itself takes a parameter (e.g. a specific custom field).
export const getGroupKey = (groupBy) =>
  groupBy.key ? `${groupBy.property}.${groupBy.key}` : groupBy.property;

// Unique id for one group within its grouping, used as the key for storing
// per-group state (collapse, visibility, order) in `displaySettings`.
export const getGroupId = ({ groupBy, value }) =>
  `${getGroupKey(groupBy)}:${value?.id ?? GROUP_NONE}`;

// Inverse of `getGroupId`; returns null for `GROUP_NONE` since it isn't a real fetchable id.
export const getGroupValueId = ({ groupBy, groupId }) => {
  const valueId = groupId.slice(`${getGroupKey(groupBy)}:`.length);
  return valueId === GROUP_NONE ? null : valueId;
};

// Variables for the first, non-paginated page. `fetchMore` merges later pages
// into whatever cache entry these variables point to, so the drag-and-drop
// cache updates have to build the exact same variables to land on that entry.
// The grouping strategy supplies `columnFilter` (e.g. `{ status: { name } }`),
// so this works the same no matter which attribute the board is grouped by.
export const boardColumnQueryVariables = ({
  rootPageFullPath,
  baseQueryVariables,
  columnFilter,
}) => ({
  fullPath: rootPageFullPath,
  ...baseQueryVariables,
  firstPageSize: DEFAULT_PAGE_SIZE_BOARD_COLUMN,
  ...columnFilter, // spread last, so it wins if a base variable uses the same key
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
