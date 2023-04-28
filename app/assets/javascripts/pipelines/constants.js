import { s__, __ } from '~/locale';

export const CANCEL_REQUEST = 'CANCEL_REQUEST';
export const FILTER_PIPELINES_SEARCH_DELAY = 200;
export const ANY_TRIGGER_AUTHOR = 'Any';
export const SUPPORTED_FILTER_PARAMETERS = ['username', 'ref', 'status', 'source'];
export const FILTER_TAG_IDENTIFIER = 'tag';
export const SCHEDULE_ORIGIN = 'schedule';
export const NEEDS_PROPERTY = 'needs';
export const EXPLICIT_NEEDS_PROPERTY = 'previousStageJobsOrNeeds';

export const ICONS = {
  TAG: 'tag',
  MR: 'git-merge',
  BRANCH: 'branch',
};

export const TestStatus = {
  FAILED: 'failed',
  SKIPPED: 'skipped',
  SUCCESS: 'success',
  ERROR: 'error',
  UNKNOWN: 'unknown',
};

export const FETCH_AUTHOR_ERROR_MESSAGE = __('There was a problem fetching project users.');
export const FETCH_BRANCH_ERROR_MESSAGE = __('There was a problem fetching project branches.');
export const FETCH_TAG_ERROR_MESSAGE = __('There was a problem fetching project tags.');
export const RAW_TEXT_WARNING = s__(
  'Pipeline|Raw text search is not currently supported. Please use the available search tokens.',
);

/* Error constants shared across graphs */
export const DEFAULT = 'default';
export const DELETE_FAILURE = 'delete_pipeline_failure';
export const DRAW_FAILURE = 'draw_failure';
export const LOAD_FAILURE = 'load_failure';
export const PARSE_FAILURE = 'parse_failure';
export const POST_FAILURE = 'post_failure';
export const UNSUPPORTED_DATA = 'unsupported_data';

export const CHILD_VIEW = 'child';

// Pipeline tabs

export const pipelineTabName = 'graph';
export const needsTabName = 'dag';
export const jobsTabName = 'builds';
export const failedJobsTabName = 'failures';
export const testReportTabName = 'test_report';
export const securityTabName = 'security';
export const licensesTabName = 'licenses';
export const codeQualityTabName = 'codequality_report';

export const validPipelineTabNames = [
  needsTabName,
  jobsTabName,
  failedJobsTabName,
  testReportTabName,
  securityTabName,
  licensesTabName,
  codeQualityTabName,
];

// Constants for the ID and IID selection dropdown
export const PipelineKeyOptions = [
  {
    text: __('Show Pipeline ID'),
    label: __('Pipeline ID'),
    value: 'id',
  },
  {
    text: __('Show Pipeline IID'),
    label: __('Pipeline IID'),
    value: 'iid',
  },
];

export const TOAST_MESSAGE = s__('Pipeline|Creating pipeline.');

export const BUTTON_TOOLTIP_RETRY = __('Retry all failed or cancelled jobs');
export const BUTTON_TOOLTIP_CANCEL = __('Cancel');

export const DEFAULT_FIELDS = [
  {
    key: 'name',
    label: __('Name'),
    columnClass: 'gl-w-20p',
  },
  {
    key: 'stage',
    label: __('Stage'),
    columnClass: 'gl-w-20p',
  },
  {
    key: 'failureMessage',
    label: __('Failure'),
    columnClass: 'gl-w-40p',
  },
  {
    key: 'actions',
    label: '',
    tdClass: 'gl-text-right',
    columnClass: 'gl-w-20p',
  },
];

export const TRACKING_CATEGORIES = {
  table: 'pipelines_table_component',
  tabs: 'pipelines_filter_tabs',
  search: 'pipelines_filtered_search',
};
