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
//     from the new visible order,
//   - every other slot in `currentOrder` — a hidden column, or one that no
//     longer exists — stays put. We can't tell those two apart here, since
//     `visibleValues` is the only list of live groups we have once the
//     values fetch is scoped to what's visible. That's fine: `orderGroups`
//     already drops an id with no matching value when it reads this order
//     back, so a stale id costs nothing and a hidden id is preserved,
//   - visible columns absent from `currentOrder` (newly added) come last.
export const reorderGroupIds = ({ visibleValues, groupBy, currentOrder = [] }) => {
  const visibleIds = visibleValues.map((value) => getGroupId({ groupBy, value }));
  const visibleSet = new Set(visibleIds);

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
    } else {
      push(id);
    }
  });

  // Visible columns that weren't in the stored order yet (newly added).
  while (nextVisible < visibleIds.length) {
    push(visibleIds[nextVisible]);
    nextVisible += 1;
  }

  return result;
};
