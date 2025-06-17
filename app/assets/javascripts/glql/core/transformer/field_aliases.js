import { glqlWorkItemsFeatureFlagEnabled } from '../../utils/feature_flags';

const fieldAliases = {
  // We don't want to expose the id (GID) field to the user, so we alias it to iid
  id: 'iid',
  assignee: 'assignees',
  closed: 'closedAt',
  created: 'createdAt',
  due: 'dueDate',
  health: 'healthStatus',
  label: 'labels',
  updated: 'updatedAt',
  description: 'descriptionHtml',

  merged: 'mergedAt',
  reviewer: 'reviewers',
  merger: 'mergedBy',
  approver: 'approvedBy',
};

if (glqlWorkItemsFeatureFlagEnabled()) {
  Object.assign(fieldAliases, {
    epic: 'parent',
    start: 'startDate',
  });
}

export const getFieldAlias = (fieldName) => fieldAliases[fieldName] || fieldName;
