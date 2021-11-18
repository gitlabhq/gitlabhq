import { __, s__ } from '~/locale';

export const i18n = {
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
};

export const NEW_NAME_FIELD = 'newName';
