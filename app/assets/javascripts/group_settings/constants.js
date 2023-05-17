import { __, s__ } from '~/locale';

export const I18N_CONFIRM_MESSAGE = s__(
  'Runners|Shared runners will be disabled for all projects and subgroups in this group. If you proceed, you must manually re-enable shared runners in the settings of each project and subgroup.',
);
export const I18N_CONFIRM_OK = s__('Runners|Yes, disable shared runners');
export const I18N_CONFIRM_CANCEL = s__('Runners|No, keep shared runners enabled');
export const I18N_CONFIRM_TITLE = s__(
  'Runners|Are you sure you want to disable shared runners for %{groupName}?',
);

export const I18N_UPDATE_ERROR_MESSAGE = __('An error occurred while updating configuration.');
export const I18N_REFRESH_MESSAGE = __('Refresh the page and try again.');
