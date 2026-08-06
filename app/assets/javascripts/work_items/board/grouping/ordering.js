import { getGroupId } from '../utils';

// Column order is persisted as its own `groupOrder` array in `displaySettings`,
// separate from `visibleGroups`/`collapsedGroups`, because order is an
// independent concern from visibility and collapse:
//   - `visibleGroups` is null when every group is shown, so it carries no order
//     to piggyback on — you must be able to reorder a board with no visibility
//     filter set at all.
//   - hiding/showing or collapsing a column shouldn't disturb the saved order.
// Since board columns are derived live from the namespace (statuses today), the
// stored order and the live set can drift; the functions below reconcile the two
// rather than treating either as authoritative — see orderGroups for the rules.

// Applies a persisted `groupOrder` (an array of group identifiers from
// `displaySettings`) to the live list of group values, reconciling on read:
//
//   - groups present in `groupOrder` keep that relative order,
//   - groups absent from `groupOrder` (e.g. a newly-added status) are appended
//     after them in their incoming default order,
//   - identifiers in `groupOrder` that no longer match a value are ignored.
//
// This means the stored order never has to be rewritten when the underlying
// groups change — it degrades gracefully as statuses are added/removed/renamed.
export const orderGroups = ({ groupOrder = [], groupBy, values = [] }) => {
  if (!Array.isArray(groupOrder) || groupOrder.length === 0) {
    return values;
  }

  const rank = new Map(groupOrder.map((id, index) => [id, index]));
  const known = [];
  const unknown = [];

  values.forEach((value) => {
    (rank.has(getGroupId({ groupBy, value })) ? known : unknown).push(value);
  });

  known.sort(
    (a, b) =>
      rank.get(getGroupId({ groupBy, value: a })) - rank.get(getGroupId({ groupBy, value: b })),
  );

  return [...known, ...unknown];
};

// Produces the `groupOrder` to persist after the visible columns have been
// reordered. Merges the new visible order back into `currentOrder` (the
// previously stored order) so that columns hidden at reorder time keep their
// stored position instead of being pushed to the end:
//   - each slot in `currentOrder` holding a visible column takes the next id
//     from the new visible order; slots holding a hidden (but still existing)
//     column stay put; stale ids are dropped,
//   - visible columns absent from `currentOrder` (newly added) come next,
//   - any remaining known columns are appended in default (query) order.
export const reorderGroupIds = ({ visibleValues, allValues, groupBy, currentOrder = [] }) => {
  const visibleIds = visibleValues.map((value) => getGroupId({ groupBy, value }));
  const visibleSet = new Set(visibleIds);
  const allSet = new Set(allValues.map((value) => getGroupId({ groupBy, value })));

  const result = [];
  const placed = new Set();
  const push = (id) => {
    if (id !== undefined && !placed.has(id)) {
      result.push(id);
      placed.add(id);
    }
  };

  let nextVisible = 0;
  currentOrder.forEach((id) => {
    if (visibleSet.has(id)) {
      push(visibleIds[nextVisible]);
      nextVisible += 1;
    } else if (allSet.has(id)) {
      // Hidden column that still exists: keep it where it was stored.
      push(id);
    }
    // Stale id (no longer a real column): drop it.
  });

  // Visible columns that weren't in the stored order yet (newly added).
  while (nextVisible < visibleIds.length) {
    push(visibleIds[nextVisible]);
    nextVisible += 1;
  }

  // Any remaining known columns (e.g. newly-added hidden ones) in default order.
  allValues.forEach((value) => push(getGroupId({ groupBy, value })));

  return result;
};
