import { STATUSES } from '~/import_entities/constants';

export function isImporting(status) {
  return [STATUSES.SCHEDULING, STATUSES.SCHEDULED, STATUSES.CREATED, STATUSES.STARTED].includes(
    status,
  );
}
