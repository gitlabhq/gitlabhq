const fieldAliases = {
  assignee: 'assignees',
  closed: 'closedAt',
  created: 'createdAt',
  due: 'dueDate',
  health: 'healthStatus',
  label: 'labels',
  updated: 'updatedAt',
};

export const getFieldAlias = (fieldName) => fieldAliases[fieldName] || fieldName;
