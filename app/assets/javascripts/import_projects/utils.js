import { STATUSES } from './constants';

// Will be expanded in future
export function isProjectImportable(project) {
  return project.importStatus === STATUSES.NONE && !project.importSource.incompatible;
}
