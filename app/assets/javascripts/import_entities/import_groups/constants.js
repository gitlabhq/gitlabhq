import { __, s__ } from '~/locale';

export const i18n = {
  ERROR_TARGET_NAMESPACE_REQUIRED: s__('BulkImport|Please select a parent group.'),
  ERROR_INVALID_FORMAT: s__(
    'GroupSettings|Please choose a group URL with no special characters or spaces.',
  ),
  ERROR_NAME_ALREADY_EXISTS: s__('BulkImport|Name already exists.'),
  ERROR_REQUIRED: __('This field is required.'),
  ERROR_NAME_ALREADY_USED_IN_SUGGESTION: s__(
    'BulkImport|Name already used as a target for another group.',
  ),
  ERROR_IMPORT: s__('BulkImport|Importing the group failed.'),
  ERROR_IMPORT_COMPLETED: s__('BulkImport|Import is finished. Pick another name for re-import'),
  ERROR_TOO_MANY_REQUESTS: s__(
    'Bulkmport|Over six imports in one minute were attempted. Wait at least one minute and try again.',
  ),

  NO_GROUPS_FOUND: s__('BulkImport|No groups found'),
  OWNER: __('Owner'),

  features: {
    projectMigration: __('projects'),
  },
};

export const NEW_NAME_FIELD = 'newName';
export const TARGET_NAMESPACE_FIELD = 'targetNamespace';

export const ROOT_NAMESPACE = { fullPath: '', id: null };

const PLACEHOLDER_STATUS_PENDING_REASSIGNMENT = 'PENDING_REASSIGNMENT';
export const PLACEHOLDER_STATUS_AWAITING_APPROVAL = 'AWAITING_APPROVAL';
const PLACEHOLDER_STATUS_REJECTED = 'REJECTED';
export const PLACEHOLDER_STATUS_REASSIGNING = 'REASSIGNMENT_IN_PROGRESS';
const PLACEHOLDER_STATUS_FAILED = 'FAILED';
export const PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER = 'KEEP_AS_PLACEHOLDER';
export const PLACEHOLDER_STATUS_COMPLETED = 'COMPLETED';

export const placeholderUserBadges = {
  [PLACEHOLDER_STATUS_PENDING_REASSIGNMENT]: {
    text: __('Not started'),
    variant: 'muted',
    tooltip: s__('UserMapping|Reassignment has not started.'),
  },
  [PLACEHOLDER_STATUS_AWAITING_APPROVAL]: {
    text: s__('UserMapping|Pending approval'),
    variant: 'warning',
    tooltip: s__('UserMapping|Reassignment waiting on user approval.'),
  },
  [PLACEHOLDER_STATUS_REJECTED]: {
    text: s__('UserMapping|Rejected'),
    variant: 'danger',
    tooltip: s__('UserMapping|Reassignment was rejected by user.'),
  },
  [PLACEHOLDER_STATUS_REASSIGNING]: {
    text: s__('UserMapping|Reassigning'),
    variant: 'info',
    tooltip: s__('UserMapping|Reassignment in progress.'),
  },
  [PLACEHOLDER_STATUS_FAILED]: {
    text: __('Failed'),
    variant: 'danger',
    tooltip: s__('UserMapping|Reassignment failed.'),
  },
  [PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER]: {
    text: s__('UserMapping|Kept as placeholder'),
    variant: 'success',
    tooltip: s__('UserMapping|Placeholder user was made permanent.'),
  },
  [PLACEHOLDER_STATUS_COMPLETED]: {
    text: __('Success'),
    variant: 'success',
    tooltip: s__('UserMapping|Reassignment succeeded.'),
  },
};
