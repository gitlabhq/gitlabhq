import { __ } from '../locale';

// The `scheduling` status is only present on the client-side,
// it is used as the status when we are requesting to start an import.

export const STATUSES = {
  FINISHED: 'finished',
  FAILED: 'failed',
  SCHEDULED: 'scheduled',
  CREATED: 'created',
  STARTED: 'started',
  NONE: 'none',
  SCHEDULING: 'scheduling',
  CANCELLED: 'cancelled',
};

const SCHEDULED_STATUS = {
  icon: 'status-scheduled',
  text: __('Pending'),
  iconClass: 'gl-text-orange-400',
};

const STATUS_MAP = {
  [STATUSES.NONE]: {
    icon: 'status-waiting',
    text: __('Not started'),
    iconClass: 'gl-text-gray-400',
  },
  [STATUSES.SCHEDULING]: SCHEDULED_STATUS,
  [STATUSES.SCHEDULED]: SCHEDULED_STATUS,
  [STATUSES.CREATED]: SCHEDULED_STATUS,
  [STATUSES.STARTED]: {
    icon: 'status-running',
    text: __('Importing...'),
    iconClass: 'gl-text-blue-400',
  },
  [STATUSES.FINISHED]: {
    icon: 'status-success',
    text: __('Complete'),
    iconClass: 'gl-text-green-400',
  },
  [STATUSES.FAILED]: {
    icon: 'status-failed',
    text: __('Failed'),
    iconClass: 'gl-text-red-600',
  },
  [STATUSES.CANCELLED]: {
    icon: 'status-stopped',
    text: __('Cancelled'),
    iconClass: 'gl-text-red-600',
  },
};

export default STATUS_MAP;
