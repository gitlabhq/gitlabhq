import { STATUSES } from '../../constants';
import * as types from './mutation_types';

const makeNewIncompatibleProject = (project) => ({
  importSource: { ...project, incompatible: true },
  importedProject: null,
});

const processLegacyEntries = ({ newRepositories, existingRepositories, factory }) => {
  const newEntries = [];
  newRepositories.forEach((project) => {
    const existingProject = existingRepositories.find((p) => p.importSource.id === project.id);
    const importedProjectShape = factory(project);

    if (existingProject) {
      Object.assign(existingProject, importedProjectShape);
    } else {
      newEntries.push(importedProjectShape);
    }
  });
  return newEntries;
};

export default {
  [types.SET_FILTER](state, newFilter) {
    state.filter = { ...state.filter, ...newFilter };
    state.repositories = [];
    state.pageInfo = {
      page: 0,
      startCursor: null,
      endCursor: null,
      hasNextPage: true,
    };
  },

  [types.REQUEST_REPOS](state) {
    state.isLoadingRepos = true;
  },

  [types.RECEIVE_REPOS_SUCCESS](state, repositories) {
    state.isLoadingRepos = false;

    if (!Array.isArray(repositories)) {
      // Legacy code path, will be removed when all importers will be switched to new pagination format
      // https://gitlab.com/gitlab-org/gitlab/-/issues/27370#note_379034091

      const incompatibleRepos = repositories.incompatibleRepos ?? [];
      const newIncompatibleProjects = processLegacyEntries({
        newRepositories: incompatibleRepos,
        existingRepositories: state.repositories,
        factory: makeNewIncompatibleProject,
      });

      const existingProjectNames = new Set(state.repositories.map((p) => p.importSource.fullName));
      const importedProjects = [...(repositories.importedProjects ?? [])].reverse();
      const newProjects = repositories.providerRepos
        .filter((project) => !existingProjectNames.has(project.fullName))
        .map((project) => {
          const importedProject = importedProjects.find(
            (p) => p.providerLink === project.providerLink,
          );

          return {
            importSource: project,
            importedProject,
          };
        });

      state.repositories = [...state.repositories, ...newProjects, ...newIncompatibleProjects];

      if (incompatibleRepos.length === 0 && repositories.providerRepos.length === 0) {
        state.pageInfo.page -= 1;
      }

      return;
    }

    state.repositories = [...state.repositories, ...repositories];
    if (repositories.length === 0) {
      state.pageInfo.page -= 1;
    }
  },

  [types.RECEIVE_REPOS_ERROR](state) {
    state.isLoadingRepos = false;
  },

  [types.REQUEST_IMPORT](state, { repoId, importTarget }) {
    const existingRepo = state.repositories.find((r) => r.importSource.id === repoId);
    existingRepo.importedProject = {
      importStatus: STATUSES.SCHEDULING,
      fullPath: `/${importTarget.targetNamespace}/${importTarget.newName}`,
    };
  },

  [types.RECEIVE_IMPORT_SUCCESS](state, { importedProject, repoId }) {
    const existingRepo = state.repositories.find((r) => r.importSource.id === repoId);
    existingRepo.importedProject = importedProject;
  },

  [types.RECEIVE_IMPORT_ERROR](state, repoId) {
    const existingRepo = state.repositories.find((r) => r.importSource.id === repoId);
    existingRepo.importedProject.importStatus = STATUSES.FAILED;
  },

  [types.RECEIVE_JOBS_SUCCESS](state, updatedProjects) {
    updatedProjects.forEach((updatedProject) => {
      const repo = state.repositories.find((p) => p.importedProject?.id === updatedProject.id);
      if (repo?.importedProject) {
        repo.importedProject = {
          ...repo.importedProject,
          stats: updatedProject.stats,
          importStatus: updatedProject.importStatus,
        };
      }
    });
  },

  [types.CANCEL_IMPORT_SUCCESS](state, { repoId }) {
    const existingRepo = state.repositories.find((r) => r.importSource.id === repoId);
    existingRepo.importedProject.importStatus = STATUSES.CANCELED;
  },

  [types.SET_IMPORT_TARGET](state, { repoId, importTarget }) {
    const existingRepo = state.repositories.find((r) => r.importSource.id === repoId);

    if (
      importTarget.targetNamespace === state.defaultTargetNamespace &&
      importTarget.newName === existingRepo.importSource.sanitizedName
    ) {
      const importsCopy = { ...state.customImportTargets };
      delete importsCopy[repoId];
      state.customImportTargets = importsCopy;
    } else {
      state.customImportTargets = {
        ...state.customImportTargets,
        [repoId]: importTarget,
      };
    }
  },

  [types.SET_PAGE](state, page) {
    state.pageInfo.page = page;
  },

  [types.SET_PAGE_CURSORS](state, pageInfo) {
    const { startCursor, endCursor, hasNextPage } = pageInfo;
    state.pageInfo = { ...state.pageInfo, startCursor, endCursor, hasNextPage };
  },

  [types.SET_HAS_NEXT_PAGE](state, hasNextPage) {
    state.pageInfo.hasNextPage = hasNextPage;
  },
};
