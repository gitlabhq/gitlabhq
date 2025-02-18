import { __, s__ } from '~/locale';

export const forwardDeploymentFailureModalId = 'forward-deployment-failure';

export const BUTTON_TOOLTIP_RETRY = __('Retry all failed or cancelled jobs');
export const BUTTON_TOOLTIP_CANCEL = __('Cancel the running pipeline');
export const BUTTON_TOOLTIP_DELETE = __('Delete the pipeline');

export const FILTER_TAG_IDENTIFIER = 'tag';

export const JOB_GRAPHQL_ERRORS = {
  jobMutationErrorText: __('There was an error running the job. Please try again.'),
  jobQueryErrorText: __('There was an error fetching the job.'),
};

export const ICONS = {
  TAG: 'tag',
  MR: 'merge-request',
  BRANCH: 'branch',
  RETRY: 'retry',
  SUCCESS: 'success',
};

export const FAILED_STATUS = 'failed';
export const PASSED_STATUS = 'passed';
export const MANUAL_STATUS = 'manual';
export const SUCCESS_STATUS = 'SUCCESS';

export const PIPELINE_ID_KEY = 'id';
export const PIPELINE_IID_KEY = 'iid';

export const RAW_TEXT_WARNING = s__(
  'Pipeline|Raw text search is not currently supported. Please use the available search tokens.',
);

export const TRACKING_CATEGORIES = {
  table: 'pipelines_table_component',
  tabs: 'pipelines_filter_tabs',
  search: 'pipelines_filtered_search',
  failed: 'pipeline_failed_jobs_tab',
  tests: 'pipeline_tests_tab',
  listbox: 'pipeline_id_iid_listbox',
};

// For pipeline polling
export const PIPELINE_POLL_INTERVAL_DEFAULT = 1000 * 8;
export const PIPELINE_POLL_INTERVAL_BACKOFF = 1.2;
export const FOUR_MINUTES_IN_MS = 1000 * 60 * 4;

export const NETWORK_STATUS_READY = 7;
