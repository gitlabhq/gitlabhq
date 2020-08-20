import { STATUSES } from '../constants';

export const isLoading = state => state.isLoadingRepos || state.isLoadingNamespaces;

export const isImportingAnyRepo = state =>
  state.repositories.some(repo =>
    [STATUSES.SCHEDULING, STATUSES.SCHEDULED, STATUSES.STARTED].includes(repo.importStatus),
  );

export const hasIncompatibleRepos = state =>
  state.repositories.some(repo => repo.importSource.incompatible);

export const hasImportableRepos = state =>
  state.repositories.some(repo => repo.importStatus === STATUSES.NONE);

export const getImportTarget = state => repoId => {
  if (state.customImportTargets[repoId]) {
    return state.customImportTargets[repoId];
  }

  const repo = state.repositories.find(r => r.importSource.id === repoId);

  return {
    newName: repo.importSource.sanitizedName,
    targetNamespace: state.defaultTargetNamespace,
  };
};
