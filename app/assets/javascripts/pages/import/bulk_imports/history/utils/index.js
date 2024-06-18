import { STATUSES } from '~/import_entities/constants';

export function isFailed(status) {
  return status === STATUSES.FAILED;
}

export function isImporting(status) {
  return [STATUSES.SCHEDULING, STATUSES.SCHEDULED, STATUSES.CREATED, STATUSES.STARTED].includes(
    status,
  );
}
