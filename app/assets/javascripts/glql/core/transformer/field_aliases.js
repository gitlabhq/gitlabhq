const fieldAliases = {
  assignee: 'assignees',
  closed: 'closedAt',
  created: 'createdAt',
  due: 'dueDate',
  health: 'healthStatus',
  label: 'labels',
  updated: 'updatedAt',
  description: 'descriptionHtml',
};

export const getFieldAlias = (fieldName) => fieldAliases[fieldName] || fieldName;
