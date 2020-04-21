export const IMPORT_STATE = {
  FAILED: 'failed',
  FINISHED: 'finished',
  NONE: 'none',
  SCHEDULED: 'scheduled',
  STARTED: 'started',
};

export const isInProgress = state =>
  state === IMPORT_STATE.SCHEDULED || state === IMPORT_STATE.STARTED;
