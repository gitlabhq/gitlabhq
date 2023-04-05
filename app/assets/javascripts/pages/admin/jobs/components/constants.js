import { s__, __ } from '~/locale';

export const CANCEL_JOBS_MODAL_ID = 'cancel-jobs-modal';
export const CANCEL_JOBS_MODAL_TITLE = s__('AdminArea|Are you sure?');
export const CANCEL_JOBS_BUTTON_TEXT = s__('AdminArea|Cancel all jobs');
export const CANCEL_BUTTON_TOOLTIP = s__('AdminArea|Cancel all running and pending jobs');
export const CANCEL_TEXT = __('Cancel');
export const CANCEL_JOBS_FAILED_TEXT = s__('AdminArea|Canceling jobs failed');
export const PRIMARY_ACTION_TEXT = s__('AdminArea|Yes, proceed');
export const CANCEL_JOBS_WARNING = s__(
  "AdminArea|You're about to cancel all running and pending jobs across this instance. Do you want to proceed?",
);
