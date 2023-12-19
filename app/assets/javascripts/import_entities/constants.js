import { __, s__ } from '~/locale';

export const STATUSES = {
  FINISHED: 'finished',
  FAILED: 'failed',
  SCHEDULED: 'scheduled',
  SCHEDULING: 'scheduling', // only present client-side, used when user is requesting to start an import
  CREATED: 'created',
  STARTED: 'started',
  NONE: 'none',
  CANCELED: 'canceled',
  TIMEOUT: 'timeout',
  PARTIAL: 'partial', // only present client-side, finished but with failures
};

export const PROVIDERS = {
  GITHUB: 'github',
  BITBUCKET_SERVER: 'bitbucket_server',
};

// Retrieved from value of `PAGE_LENGTH` in lib/bitbucket_server/paginator.rb
export const BITBUCKET_SERVER_PAGE_LENGTH = 25;

const SCHEDULED_STATUS_ICON = {
  icon: 'status-scheduled',
  text: __('Pending'),
  variant: 'muted',
};

export const STATUS_ICON_MAP = {
  [STATUSES.NONE]: {
    icon: 'status-waiting',
    text: __('Not started'),
    variant: 'muted',
  },
  [STATUSES.SCHEDULING]: SCHEDULED_STATUS_ICON,
  [STATUSES.SCHEDULED]: SCHEDULED_STATUS_ICON,
  [STATUSES.CREATED]: SCHEDULED_STATUS_ICON,
  [STATUSES.STARTED]: {
    icon: 'status-running',
    text: __('Importing...'),
    variant: 'info',
  },
  [STATUSES.FAILED]: {
    icon: 'status-failed',
    text: __('Failed'),
    variant: 'danger',
  },
  [STATUSES.TIMEOUT]: {
    icon: 'status-failed',
    text: __('Timeout'),
    variant: 'danger',
  },
  [STATUSES.CANCELED]: {
    icon: 'status-stopped',
    text: __('Cancelled'),
    variant: 'neutral',
  },
  [STATUSES.FINISHED]: {
    icon: 'status-success',
    text: __('Complete'),
    variant: 'success',
  },
  [STATUSES.PARTIAL]: {
    icon: 'status-alert',
    text: s__('Import|Partially completed'),
    variant: 'warning',
  },
};
