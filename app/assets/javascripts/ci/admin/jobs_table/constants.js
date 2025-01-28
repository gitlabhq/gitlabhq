import { s__, __ } from '~/locale';
import { RAW_TEXT_WARNING } from '~/ci/jobs_page/constants';

export const JOBS_COUNT_ERROR_MESSAGE = __('There was an error fetching the number of jobs.');
export const JOBS_FETCH_ERROR_MSG = __('There was an error fetching the jobs.');
export const LOADING_ARIA_LABEL = __('Loading');
export const CANCELABLE_JOBS_ERROR_MSG = __('There was an error fetching the cancelable jobs.');
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
export const RUNNER_EMPTY_TEXT = __('None');
export const RUNNER_NO_DESCRIPTION = s__('Runners|No description');

/* Admin Table constants */
/* The field list is based on app/assets/javascripts/jobs/components/table/constants.js */
export const DEFAULT_FIELDS_ADMIN = [
  { key: 'status', label: __('Status'), columnClass: 'gl-w-3/20' },
  { key: 'job', label: __('Job'), columnClass: 'gl-w-4/20', isRowHeader: true },
  { key: 'project', label: __('Project'), columnClass: 'gl-w-4/20' },
  { key: 'runner', label: __('Runner'), columnClass: 'gl-w-3/20' },
  { key: 'pipeline', label: __('Pipeline'), columnClass: 'gl-w-2/20' },
  { key: 'actions', label: '', columnClass: 'gl-w-2/20' },
];

export const RAW_TEXT_WARNING_ADMIN = RAW_TEXT_WARNING;
export const VIEW_ADMIN_JOBS_PAGELOAD = 'view_admin_jobs_pageload';
