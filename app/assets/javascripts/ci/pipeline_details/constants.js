import { __, s__ } from '~/locale';

export const CANCEL_REQUEST = 'CANCEL_REQUEST';
export const SUPPORTED_FILTER_PARAMETERS = ['username', 'ref', 'status', 'source'];
export const NEEDS_PROPERTY = 'needs';
export const EXPLICIT_NEEDS_PROPERTY = 'previousStageJobsOrNeeds';

export const testStatus = {
  FAILED: 'failed',
  SKIPPED: 'skipped',
  SUCCESS: 'success',
  ERROR: 'error',
  UNKNOWN: 'unknown',
};

/* Error constants shared across graphs */
export const DEFAULT = 'default';
export const DELETE_FAILURE = 'delete_pipeline_failure';
export const DRAW_FAILURE = 'draw_failure';
export const LOAD_FAILURE = 'load_failure';
export const POST_FAILURE = 'post_failure';

// Pipeline tabs

export const pipelineTabName = 'graph';
export const jobsTabName = 'builds';
export const failedJobsTabName = 'failures';
export const testReportTabName = 'test_report';
export const manualVariablesTabName = 'manual_variables';
export const securityTabName = 'security';
export const licensesTabName = 'licenses';
export const codeQualityTabName = 'codequality_report';

export const validPipelineTabNames = [
  jobsTabName,
  failedJobsTabName,
  testReportTabName,
  securityTabName,
  licensesTabName,
  codeQualityTabName,
  manualVariablesTabName,
];

export const TOAST_MESSAGE = s__('Pipeline|Creating pipeline.');

export const DEFAULT_FIELDS = [
  {
    key: 'name',
    label: __('Name'),
    columnClass: 'gl-w-1/5',
  },
  {
    key: 'stage',
    label: __('Stage'),
    columnClass: 'gl-w-1/5',
  },
  {
    key: 'failureMessage',
    label: __('Failure'),
    columnClass: 'gl-w-2/5',
  },
  {
    key: 'actions',
    label: '',
    tdClass: 'gl-text-right',
    columnClass: 'gl-w-1/5',
  },
];
