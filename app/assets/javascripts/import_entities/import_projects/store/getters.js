import { isProjectImportable, isIncompatible, isImporting } from '../utils';

export const importingRepoCount = (state) => state.repositories.filter(isImporting).length;

export const isImportingAnyRepo = (state) => state.repositories.some(isImporting);

export const hasIncompatibleRepos = (state) => state.repositories.some(isIncompatible);

export const hasImportableRepos = (state) => state.repositories.some(isProjectImportable);

export const importAllCount = (state) => state.repositories.filter(isProjectImportable).length;

export const getImportTarget = (state) => (repoId) => {
  if (state.customImportTargets[repoId]) {
    return state.customImportTargets[repoId];
  }

  const repo = state.repositories.find((r) => r.importSource.id === repoId);

  return {
    newName: repo.importSource.sanitizedName,
    targetNamespace: state.defaultTargetNamespace,
  };
};
