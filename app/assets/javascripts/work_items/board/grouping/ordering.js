import { getGroupId } from './identity';

// Column order lives in its own `groupOrder` array, separate from `visibleGroups`/
// `collapsedGroups` — `visibleGroups` is null when everything is shown, so it can't
// double as a place to store order, and hiding a column shouldn't reorder it.
//
// Columns come from the namespace live (statuses today), so the stored order
// can drift out of sync with the real set over time. The functions below
// reconcile the two rather than trusting either one blindly.

// Groups already in `groupOrder` keep that relative order; anything else keeps
// its incoming order and goes to the end.
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

// Works out the new `groupOrder` to save after reordering the visible columns. Slots the
// new order back into `currentOrder` so a hidden column keeps its stored spot — orderGroups
// drops stale ids later, so this doesn't need to tell hidden and stale apart.
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
