import { getGroupId } from '../utils';

// No visibility filter applied: every group shows.
export const SHOW_ALL_GROUPS = null;

// An unhydrated cache read gives `undefined`, so anything that isn't an
// explicit list counts as unfiltered.
const showAllGroups = (visibleGroups) => !Array.isArray(visibleGroups);

export const isGroupVisible = (visibleGroups, groupBy, value) =>
  showAllGroups(visibleGroups) || visibleGroups.includes(getGroupId({ groupBy, value }));

// Needs the full candidate list from the caller since visibility doesn't own
// the complete set of groups.
export const toggleGroupVisibility = ({ visibleGroups, groupBy, value, allValues }) => {
  const id = getGroupId({ groupBy, value });
  const allGroupIds = allValues.map((candidate) => getGroupId({ groupBy, value: candidate }));
  const current = showAllGroups(visibleGroups) ? allGroupIds : visibleGroups;
  const next = current.includes(id)
    ? current.filter((groupId) => groupId !== id)
    : [...current, id];

  // Collapse back to unfiltered once everything is visible again.
  return allGroupIds.every((groupId) => next.includes(groupId)) ? SHOW_ALL_GROUPS : next;
};
