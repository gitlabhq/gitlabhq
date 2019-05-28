import { __ } from '../locale';

// The `scheduling` status is only present on the client-side,
// it is used as the status when we are requesting to start an import.

export const STATUSES = {
  FINISHED: 'finished',
  FAILED: 'failed',
  SCHEDULED: 'scheduled',
  STARTED: 'started',
  NONE: 'none',
  SCHEDULING: 'scheduling',
};

const STATUS_MAP = {
  [STATUSES.FINISHED]: {
    icon: 'success',
    text: __('Done'),
    textClass: 'text-success',
  },
  [STATUSES.FAILED]: {
    icon: 'failed',
    text: __('Failed'),
    textClass: 'text-danger',
  },
  [STATUSES.SCHEDULED]: {
    icon: 'pending',
    text: __('Scheduled'),
    textClass: 'text-warning',
  },
  [STATUSES.STARTED]: {
    icon: 'running',
    text: __('Running…'),
    textClass: 'text-info',
  },
  [STATUSES.NONE]: {
    icon: 'created',
    text: __('Not started'),
    textClass: 'text-muted',
  },
  [STATUSES.SCHEDULING]: {
    loadingIcon: true,
    text: __('Scheduling'),
    textClass: 'text-warning',
  },
};

export default STATUS_MAP;
