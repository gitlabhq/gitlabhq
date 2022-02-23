import { s__, __ } from '~/locale';
import { DEFAULT_TH_CLASSES } from '~/lib/utils/constants';

/* Error constants */
export const POST_FAILURE = 'post_failure';
export const DEFAULT = 'default';

/* Job Status Constants */
export const JOB_SCHEDULED = 'SCHEDULED';

/* Artifact file types */
export const FILE_TYPE_ARCHIVE = 'ARCHIVE';

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

/* Table constants */

const defaultTableClasses = {
  tdClass: 'gl-p-5!',
  thClass: DEFAULT_TH_CLASSES,
};
// eslint-disable-next-line @gitlab/require-i18n-strings
const coverageTdClasses = `${defaultTableClasses.tdClass} gl-display-none! gl-lg-display-table-cell!`;

export const DEFAULT_FIELDS = [
  {
    key: 'status',
    label: __('Status'),
    ...defaultTableClasses,
    columnClass: 'gl-w-10p',
  },
  {
    key: 'job',
    label: __('Job'),
    ...defaultTableClasses,
    columnClass: 'gl-w-20p',
  },
  {
    key: 'pipeline',
    label: __('Pipeline'),
    ...defaultTableClasses,
    columnClass: 'gl-w-10p',
  },
  {
    key: 'stage',
    label: __('Stage'),
    ...defaultTableClasses,
    columnClass: 'gl-w-10p',
  },
  {
    key: 'name',
    label: __('Name'),
    ...defaultTableClasses,
    columnClass: 'gl-w-15p',
  },
  {
    key: 'duration',
    label: __('Duration'),
    ...defaultTableClasses,
    columnClass: 'gl-w-15p',
  },
  {
    key: 'coverage',
    label: __('Coverage'),
    tdClass: coverageTdClasses,
    thClass: defaultTableClasses.thClass,
    columnClass: 'gl-w-10p',
  },
  {
    key: 'actions',
    label: '',
    ...defaultTableClasses,
    columnClass: 'gl-w-10p',
  },
];

export const JOBS_TAB_FIELDS = DEFAULT_FIELDS.filter((field) => field.key !== 'pipeline');
