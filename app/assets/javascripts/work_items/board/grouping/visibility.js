import { getGroupId } from './identity';

// No filter applied: every group is shown.
export const SHOW_ALL_GROUPS = null;

// Each column runs its own query, so uncapped grouping means dozens of concurrent requests.
export const MAX_VISIBLE_GROUPS = 25;

// Reading this from the cache before it's been written gives `undefined`, not
// `null`, so we treat anything that isn't a real array as "show everything"
// rather than checking for `null` specifically.
const showAllGroups = (visibleGroups) => !Array.isArray(visibleGroups);

export const exceedsGroupLimit = (groupCount) => groupCount > MAX_VISIBLE_GROUPS;

// "Show all" only makes sense while there are few enough groups to show. Past the limit,
// nothing shows until the user picks, so the board and the picker never disagree.
export const effectiveVisibleGroups = (visibleGroups, totalGroupCount) =>
  showAllGroups(visibleGroups) && exceedsGroupLimit(totalGroupCount) ? [] : visibleGroups;

export const isGroupVisible = (visibleGroups, groupBy, value) =>
  showAllGroups(visibleGroups) || visibleGroups.includes(getGroupId({ groupBy, value }));

// The caller has to pass in the full list of groups, since this function only
// deals with visibility and doesn't know the complete set on its own.
export const toggleGroupVisibility = ({ visibleGroups, groupBy, value, allGroups }) => {
  const id = getGroupId({ groupBy, value });
  const allGroupIds = allGroups.map((candidate) => getGroupId({ groupBy, value: candidate }));
  const current = showAllGroups(visibleGroups) ? allGroupIds : visibleGroups;
  const next = current.includes(id)
    ? current.filter((groupId) => groupId !== id)
    : [...current, id];

  return allGroupIds.every((groupId) => next.includes(groupId)) ? SHOW_ALL_GROUPS : next;
};
