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
