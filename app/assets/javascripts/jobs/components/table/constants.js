import { s__, __ } from '~/locale';

export const GRAPHQL_PAGE_SIZE = 30;

export const initialPaginationState = {
  currentPage: 1,
  prevPageCursor: '',
  nextPageCursor: '',
  first: GRAPHQL_PAGE_SIZE,
  last: null,
};

/* Error constants */
export const POST_FAILURE = 'post_failure';
export const DEFAULT = 'default';

/* Job Status Constants */
export const JOB_SCHEDULED = 'SCHEDULED';

/* i18n */
export const ACTIONS_DOWNLOAD_ARTIFACTS = __('Download artifacts');
export const ACTIONS_START_NOW = s__('DelayedJobs|Start now');
export const ACTIONS_UNSCHEDULE = s__('DelayedJobs|Unschedule');
export const ACTIONS_PLAY = __('Play');
export const ACTIONS_RETRY = __('Retry');

export const CANCEL = __('Cancel');
export const GENERIC_ERROR = __('An error occurred while making the request.');
export const PLAY_JOB_CONFIRMATION_MESSAGE = s__(
  `DelayedJobs|Are you sure you want to run %{job_name} immediately? This job will run automatically after its timer finishes.`,
);
export const RUN_JOB_NOW_HEADER_TITLE = s__('DelayedJobs|Run the delayed job now?');
