import { STATUSES } from '../constants';

export function isIncompatible(project) {
  return project.importSource.incompatible;
}

export function getImportStatus(project) {
  return project.importedProject?.importStatus ?? STATUSES.NONE;
}

export function isProjectImportable(project) {
  return !isIncompatible(project) && getImportStatus(project) === STATUSES.NONE;
}

export function isImporting(repo) {
  return [STATUSES.SCHEDULING, STATUSES.SCHEDULED, STATUSES.STARTED].includes(
    repo.importedProject?.importStatus,
  );
}
