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
    state.workspacePagingInfo = {};
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
      const matchedProviderLinks = new Set();

      const newProjects = repositories.providerRepos
        .filter((project) => !existingProjectNames.has(project.fullName))
        .map((project) => {
          const importedProject = importedProjects.find(
            (p) => p.providerLink === project.providerLink,
          );

          if (importedProject) {
            matchedProviderLinks.add(importedProject.providerLink);
          }

          return {
            importSource: project,
            importedProject,
          };
        });

      // Include imported projects whose source repo no longer exists on the provider
      // (e.g. deleted during or after import) so failed/completed imports remain visible.
      // Also filter out orphans already present from a previous page load to avoid duplicates.
      const existingImportedProjectIds = new Set(
        state.repositories.map((r) => r.importedProject?.id).filter(Boolean),
      );
      const unmatchedImportedProjects = importedProjects
        .filter(
          (p) => !matchedProviderLinks.has(p.providerLink) && !existingImportedProjectIds.has(p.id),
        )
        .map((importedProject) => ({
          importSource: {
            id: importedProject.id,
            fullName: importedProject.importSource,
            sanitizedName: importedProject.importSource,
            providerLink: importedProject.providerLink,
            target: (importedProject.fullPath ?? '').replace(/^\//, ''),
          },
          importedProject,
        }));

      state.repositories = [
        ...state.repositories,
        ...newProjects,
        ...unmatchedImportedProjects,
        ...newIncompatibleProjects,
      ];

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

  [types.SET_PAGE_CURSORS](state, payload) {
    const { startCursor, endCursor, hasNextPage, workspacePagingInfo } = payload;
    state.pageInfo = { ...state.pageInfo, startCursor, endCursor, hasNextPage };

    if (workspacePagingInfo) {
      state.workspacePagingInfo = workspacePagingInfo.reduce((acc, info) => {
        acc[info.workspace] = {
          nextPage: info.pageInfo.nextPage,
          hasNextPage: info.pageInfo.hasNextPage,
        };
        return acc;
      }, {});
    }
  },

  [types.SET_HAS_NEXT_PAGE](state, hasNextPage) {
    state.pageInfo.hasNextPage = hasNextPage;
  },
};
