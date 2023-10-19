import { s__, __ } from '~/locale';

/* Error constants */
export const DEFAULT = 'default';
export const RAW_TEXT_WARNING = s__(
  'Jobs|Raw text search is not currently supported for the jobs filtered search feature. Please use the available search tokens.',
);

/* Job Status Constants */
export const JOB_SCHEDULED = 'SCHEDULED';
export const JOB_SUCCESS = 'SUCCESS';

/* Artifact file types */
export const FILE_TYPE_ARCHIVE = 'ARCHIVE';

/* i18n */
export const ACTIONS_DOWNLOAD_ARTIFACTS = __('Download artifacts');
export const ACTIONS_START_NOW = s__('DelayedJobs|Start now');
export const ACTIONS_UNSCHEDULE = s__('DelayedJobs|Unschedule');
export const ACTIONS_PLAY = __('Play');
export const ACTIONS_RETRY = __('Retry');
export const ACTIONS_RUN_AGAIN = __('Run again');

export const CANCEL = __('Cancel');
export const GENERIC_ERROR = __('An error occurred while making the request.');
export const PLAY_JOB_CONFIRMATION_MESSAGE = s__(
  `DelayedJobs|Are you sure you want to run %{job_name} immediately? This job will run automatically after its timer finishes.`,
);
export const RUN_JOB_NOW_HEADER_TITLE = s__('DelayedJobs|Run the delayed job now?');

/* Table constants */
/* There is another field list based on this one in app/assets/javascripts/ci/admin/jobs_table/constants.js */
export const DEFAULT_FIELDS = [
  {
    key: 'status',
    label: __('Status'),
    columnClass: 'gl-w-10p',
  },
  {
    key: 'job',
    label: __('Job'),
    columnClass: 'gl-w-quarter',
  },
  {
    key: 'pipeline',
    label: __('Pipeline'),
    columnClass: 'gl-w-10p',
  },
  {
    key: 'stage',
    label: __('Stage'),
    columnClass: 'gl-w-10p',
  },
  {
    key: 'coverage',
    label: __('Coverage'),
    tdClass: 'gl-display-none! gl-lg-display-table-cell!',
    columnClass: 'gl-w-10p',
  },
  {
    key: 'actions',
    label: '',
    tdClass: 'gl-text-right',
    columnClass: 'gl-w-10p',
  },
];

export const JOBS_DEFAULT_FIELDS = DEFAULT_FIELDS.filter((field) => field.key !== 'stage');
export const JOBS_TAB_FIELDS = DEFAULT_FIELDS.filter((field) => field.key !== 'pipeline');
