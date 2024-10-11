import { __, s__ } from '~/locale';

export const I18N_CONFIRM_MESSAGE = s__(
  'Runners|Instance runners will be disabled for all projects and subgroups in this group.',
);
export const I18N_CONFIRM_OK = s__('Runners|Yes, disable instance runners');
export const I18N_CONFIRM_CANCEL = s__('Runners|No, keep instance runners enabled');
export const I18N_CONFIRM_TITLE = s__(
  'Runners|Are you sure you want to disable instance runners for %{groupName}?',
);

export const I18N_UPDATE_ERROR_MESSAGE = __('An error occurred while updating configuration.');
export const I18N_REFRESH_MESSAGE = __('Refresh the page and try again.');

export const I18N_PENDING_MESSAGE = s__('GroupSettings|Saving...');
export const I18N_SUCCESS_MESSAGE = s__('GroupSettings|Change saved.');
export const I18N_ERROR_MESSAGE = s__('GroupSettings|Failed to save changes.');
export const I18N_RETRY_ACTION_TEXT = s__('GroupSettings|Retry');
export const I18N_UNDO_ACTION_TEXT = s__('GroupSettings|Undo');
