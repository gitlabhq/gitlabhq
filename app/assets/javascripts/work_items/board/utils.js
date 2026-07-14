import getBoardWorkItemsQuery from 'ee_else_ce/work_items/board/graphql/get_board_work_items.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';
import { DEFAULT_PAGE_SIZE_BOARD_COLUMN } from '~/work_items/constants';

// Board columns and the drag-and-drop cache updates must use the exact same
// query so they share a single Apollo cache entry.
export const boardColumnQuery = (glFeatures) =>
  glFeatures.workItemRestApiFrontendUsers ? getWorkItemsRestQuery : getBoardWorkItemsQuery;

// Group identity helpers are shared across grouped views (board columns now,
// list grouping later), so they speak in terms of "groups" rather than columns.

// Sentinel value id for the null/unassigned group of groupings that have one
// (for example "No label", "Unassigned"). Status always has a value, so a
// "No status" group does not exist — this is here for future groupings.
export const GROUP_NONE = 'none';

// The grouping dimension a group belongs to, including a sub-key when the
// dimension itself is parameterized (for example a specific custom field).
export const getGroupKey = (groupBy) =>
  groupBy.key ? `${groupBy.property}.${groupBy.key}` : groupBy.property;

// Canonical, grouping-scoped group identifier used to persist per-group state
// (collapse now; hide and order later) in `displaySettings`.
export const getGroupId = ({ groupBy, value }) =>
  `${getGroupKey(groupBy)}:${value?.id ?? GROUP_NONE}`;

// The initial (non-paginated) query variables — the cache key `fetchMore` merges
// pages into, which the drag-and-drop cache updates must match exactly. The
// grouping strategy supplies `columnFilter` (e.g. `{ status: { name } }`), so the
// board stays agnostic to which attribute it is grouped by.
export const boardColumnQueryVariables = ({
  rootPageFullPath,
  baseQueryVariables,
  columnFilter,
}) => ({
  fullPath: rootPageFullPath,
  ...baseQueryVariables,
  firstPageSize: DEFAULT_PAGE_SIZE_BOARD_COLUMN,
  ...columnFilter, // must be last to override colliding base variables
});

// The count-only query uses a different query document so it always has its own cache
// entry. `firstPageSize` is stripped because the count query doesn't accept it, and
// board_view keys its drag-and-drop count updates off these same variables.
export const boardColumnCountVariables = (params) => {
  const { firstPageSize, ...countVariables } = boardColumnQueryVariables(params);
  return countVariables;
};

// Relative-position arguments for a card move, derived from the target column's
// pre-move order (`nodes`). For a same-column move the source and target lists
// are identical. Mirrors the neighbour logic in boards/components/board_list.vue
// so both boards order items the same way. IDs are full GraphQL global IDs —
// the workItemUpdate mutation parses the gid server-side.
export const getMovePositionIds = ({ nodes = [], sameColumn, oldIndex, newIndex }) => {
  const idAt = (index) => nodes[index]?.id;

  if (sameColumn) {
    // Moving down: the card at the drop index ends up before the moved card.
    if (newIndex > oldIndex) {
      return { moveBeforeId: idAt(newIndex) };
    }
    // Moving up: the card at the drop index ends up after the moved card.
    if (newIndex < oldIndex) {
      return { moveAfterId: idAt(newIndex) };
    }
    // Dropped in place — no reordering.
    return {};
  }

  // Cross-column: the moved card is inserted at newIndex, so its neighbours are
  // the cards currently surrounding that slot.
  return { moveBeforeId: idAt(newIndex - 1), moveAfterId: idAt(newIndex) };
};
