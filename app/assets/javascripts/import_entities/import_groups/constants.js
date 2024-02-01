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
