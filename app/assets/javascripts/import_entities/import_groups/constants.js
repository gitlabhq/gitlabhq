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
  LEARN_MORE: __('Learn more.'),

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
export const PLACEHOLDER_STATUS_FAILED = 'FAILED';
export const PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER = 'KEEP_AS_PLACEHOLDER';
export const PLACEHOLDER_STATUS_COMPLETED = 'COMPLETED';

export const PLACEHOLDER_USER_STATUS = {
  UNASSIGNED: [
    PLACEHOLDER_STATUS_PENDING_REASSIGNMENT,
    PLACEHOLDER_STATUS_AWAITING_APPROVAL,
    PLACEHOLDER_STATUS_REJECTED,
    PLACEHOLDER_STATUS_REASSIGNING,
    PLACEHOLDER_STATUS_FAILED,
  ],
  REASSIGNED: [PLACEHOLDER_STATUS_COMPLETED, PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER],
};

export const PLACEHOLDER_TAB_REASSIGNED = 'reassigned';
export const PLACEHOLDER_TAB_AWAITING = 'awaiting';

export const PLACEHOLDER_USER_UNASSIGNED_STATUS_OPTIONS = [
  {
    value: PLACEHOLDER_STATUS_PENDING_REASSIGNMENT.toLowerCase(),
    title: __('Not started'),
  },
  {
    value: PLACEHOLDER_STATUS_AWAITING_APPROVAL.toLowerCase(),
    title: s__('UserMapping|Pending approval'),
  },
  {
    value: PLACEHOLDER_STATUS_REJECTED.toLowerCase(),
    title: s__('UserMapping|Rejected'),
  },
  {
    value: PLACEHOLDER_STATUS_REASSIGNING.toLowerCase(),
    title: s__('UserMapping|Reassigning'),
  },
  {
    value: PLACEHOLDER_STATUS_FAILED.toLowerCase(),
    title: __('Failed'),
  },
];

export const PLACEHOLDER_USER_REASSIGNED_STATUS_OPTIONS = [
  {
    value: PLACEHOLDER_STATUS_KEPT_AS_PLACEHOLDER.toLowerCase(),
    title: s__('UserMapping|Kept as placeholder'),
  },
  {
    value: PLACEHOLDER_STATUS_COMPLETED.toLowerCase(),
    title: __('Success'),
  },
];

export const placeholderUserBadges = {
  [PLACEHOLDER_STATUS_PENDING_REASSIGNMENT]: {
    text: __('Not started'),
    variant: 'muted',
    tooltip: s__('UserMapping|Reassignment not started.'),
  },
  [PLACEHOLDER_STATUS_AWAITING_APPROVAL]: {
    text: s__('UserMapping|Pending approval'),
    variant: 'warning',
    tooltip: s__('UserMapping|Reassignment waiting on user approval.'),
  },
  [PLACEHOLDER_STATUS_REJECTED]: {
    text: s__('UserMapping|Rejected'),
    variant: 'danger',
    tooltip: s__('UserMapping|Reassignment rejected by user.'),
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
    tooltip: s__('UserMapping|Placeholder user made permanent.'),
  },
  [PLACEHOLDER_STATUS_COMPLETED]: {
    text: __('Success'),
    variant: 'success',
    tooltip: s__('UserMapping|Reassignment succeeded.'),
  },
};

export const PLACEHOLDER_SORT_STATUS_DESC = 'STATUS_DESC';
export const PLACEHOLDER_SORT_STATUS_ASC = 'STATUS_ASC';
export const PLACEHOLDER_SORT_SOURCE_NAME_ASC = 'SOURCE_NAME_ASC';
export const PLACEHOLDER_SORT_SOURCE_NAME_DESC = 'SOURCE_NAME_DESC';
