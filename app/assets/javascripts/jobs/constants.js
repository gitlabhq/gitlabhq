import { __, s__ } from '~/locale';

const cancel = __('Cancel');
const moreInfo = __('More information');

export const JOB_SIDEBAR = {
  cancel,
  debug: __('Debug'),
  newIssue: __('New issue'),
  retry: __('Retry'),
  toggleSidebar: __('Toggle Sidebar'),
};

export const JOB_RETRY_FORWARD_DEPLOYMENT_MODAL = {
  cancel,
  info: s__(
    `Jobs|You're about to retry a job that failed because it attempted to deploy code that is older than the latest deployment.
    Retrying this job could result in overwriting the environment with the older source code.`,
  ),
  areYouSure: s__('Jobs|Are you sure you want to proceed?'),
  moreInfo,
  primaryText: __('Retry job'),
  title: s__('Jobs|Are you sure you want to retry this job?'),
};

export const SUCCESS_STATUS = 'SUCCESS';

export const INFINITELY_NESTED_COLLAPSIBLE_SECTIONS_FF = 'infinitelyCollapsibleSections';
