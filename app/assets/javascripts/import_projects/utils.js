import { STATUSES } from './constants';

// Will be expanded in future
// eslint-disable-next-line import/prefer-default-export
export function isProjectImportable(project) {
  return project.importStatus === STATUSES.NONE && !project.importSource.incompatible;
}
