import Vue from 'vue';
import * as types from './mutation_types';
import { STATUSES } from '../constants';

const makeNewImportedProject = importedProject => ({
  importSource: {
    id: importedProject.id,
    fullName: importedProject.importSource,
    sanitizedName: importedProject.name,
    providerLink: importedProject.providerLink,
  },
  importedProject,
});

const makeNewIncompatibleProject = project => ({
  importSource: { ...project, incompatible: true },
  importedProject: null,
});

const processLegacyEntries = ({ newRepositories, existingRepositories, factory }) => {
  const newEntries = [];
  newRepositories.forEach(project => {
    const existingProject = existingRepositories.find(p => p.importSource.id === project.id);
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
  [types.SET_FILTER](state, filter) {
    state.filter = filter;
    state.repositories = [];
    state.pageInfo.page = 0;
  },

  [types.REQUEST_REPOS](state) {
    state.isLoadingRepos = true;
  },

  [types.RECEIVE_REPOS_SUCCESS](state, repositories) {
    state.isLoadingRepos = false;

    if (!Array.isArray(repositories)) {
      // Legacy code path, will be removed when all importers will be switched to new pagination format
      // https://gitlab.com/gitlab-org/gitlab/-/issues/27370#note_379034091

      const newImportedProjects = processLegacyEntries({
        newRepositories: repositories.importedProjects,
        existingRepositories: state.repositories,
        factory: makeNewImportedProject,
      });

      const incompatibleRepos = repositories.incompatibleRepos ?? [];
      const newIncompatibleProjects = processLegacyEntries({
        newRepositories: incompatibleRepos,
        existingRepositories: state.repositories,
        factory: makeNewIncompatibleProject,
      });

      state.repositories = [
        ...newImportedProjects,
        ...state.repositories,
        ...repositories.providerRepos.map(project => ({
          importSource: project,
          importedProject: null,
        })),
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
    const existingRepo = state.repositories.find(r => r.importSource.id === repoId);
    existingRepo.importedProject = {
      importStatus: STATUSES.SCHEDULING,
      fullPath: `/${importTarget.targetNamespace}/${importTarget.newName}`,
    };
  },

  [types.RECEIVE_IMPORT_SUCCESS](state, { importedProject, repoId }) {
    const existingRepo = state.repositories.find(r => r.importSource.id === repoId);
    existingRepo.importedProject = importedProject;
  },

  [types.RECEIVE_IMPORT_ERROR](state, repoId) {
    const existingRepo = state.repositories.find(r => r.importSource.id === repoId);
    existingRepo.importedProject = null;
  },

  [types.RECEIVE_JOBS_SUCCESS](state, updatedProjects) {
    updatedProjects.forEach(updatedProject => {
      const repo = state.repositories.find(p => p.importedProject?.id === updatedProject.id);
      if (repo?.importedProject) {
        repo.importedProject.importStatus = updatedProject.importStatus;
      }
    });
  },

  [types.REQUEST_NAMESPACES](state) {
    state.isLoadingNamespaces = true;
  },

  [types.RECEIVE_NAMESPACES_SUCCESS](state, namespaces) {
    state.isLoadingNamespaces = false;
    state.namespaces = namespaces;
  },

  [types.RECEIVE_NAMESPACES_ERROR](state) {
    state.isLoadingNamespaces = false;
  },

  [types.SET_IMPORT_TARGET](state, { repoId, importTarget }) {
    const existingRepo = state.repositories.find(r => r.importSource.id === repoId);

    if (
      importTarget.targetNamespace === state.defaultTargetNamespace &&
      importTarget.newName === existingRepo.importSource.sanitizedName
    ) {
      Vue.delete(state.customImportTargets, repoId);
    } else {
      Vue.set(state.customImportTargets, repoId, importTarget);
    }
  },

  [types.SET_PAGE](state, page) {
    state.pageInfo.page = page;
  },
};
