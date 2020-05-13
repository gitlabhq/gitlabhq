import { __ } from '~/locale';

export const CANCEL_REQUEST = 'CANCEL_REQUEST';
export const PIPELINES_TABLE = 'PIPELINES_TABLE';
export const LAYOUT_CHANGE_DELAY = 300;
export const FILTER_PIPELINES_SEARCH_DELAY = 200;
export const ANY_TRIGGER_AUTHOR = 'Any';

export const TestStatus = {
  FAILED: 'failed',
  SKIPPED: 'skipped',
  SUCCESS: 'success',
};

export const FETCH_AUTHOR_ERROR_MESSAGE = __('There was a problem fetching project users.');
export const FETCH_BRANCH_ERROR_MESSAGE = __('There was a problem fetching project branches.');
