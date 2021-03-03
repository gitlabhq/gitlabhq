import { s__, __ } from '~/locale';

export const CANCEL_REQUEST = 'CANCEL_REQUEST';
export const LAYOUT_CHANGE_DELAY = 300;
export const FILTER_PIPELINES_SEARCH_DELAY = 200;
export const ANY_TRIGGER_AUTHOR = 'Any';
export const SUPPORTED_FILTER_PARAMETERS = ['username', 'ref', 'status'];
export const FILTER_TAG_IDENTIFIER = 'tag';
export const SCHEDULE_ORIGIN = 'schedule';

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
export const EMPTY_PIPELINE_DATA = 'empty_data';
export const INVALID_CI_CONFIG = 'invalid_ci_config';
export const LOAD_FAILURE = 'load_failure';
export const PARSE_FAILURE = 'parse_failure';
export const POST_FAILURE = 'post_failure';
export const UNSUPPORTED_DATA = 'unsupported_data';

export const CHILD_VIEW = 'child';
