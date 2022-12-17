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
  CANCELED: 'canceled',
  TIMEOUT: 'timeout',
};

export const PROVIDERS = {
  GITHUB: 'github',
};
