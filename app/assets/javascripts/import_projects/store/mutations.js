import Vue from 'vue';
import * as types from './mutation_types';
import { STATUSES } from '../constants';

export default {
  [types.SET_FILTER](state, filter) {
    state.filter = filter;
  },

  [types.REQUEST_REPOS](state) {
    state.isLoadingRepos = true;
  },

  [types.RECEIVE_REPOS_SUCCESS](state, repositories) {
    state.isLoadingRepos = false;

    if (!Array.isArray(repositories)) {
      // Legacy code path, will be removed when all importers will be switched to new pagination format
      // https://gitlab.com/gitlab-org/gitlab/-/issues/27370#note_379034091
      state.repositories = [
        ...repositories.importedProjects.map(importedProject => ({
          importSource: {
            id: importedProject.id,
            fullName: importedProject.importSource,
            sanitizedName: importedProject.name,
            providerLink: importedProject.providerLink,
          },
          importedProject,
        })),
        ...repositories.providerRepos.map(project => ({
          importSource: project,
          importedProject: null,
        })),
        ...(repositories.incompatibleRepos ?? []).map(project => ({
          importSource: { ...project, incompatible: true },
          importedProject: null,
        })),
      ];

      return;
    }

    state.repositories = repositories;
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

  [types.SET_PAGE_INFO](state, pageInfo) {
    state.pageInfo = pageInfo;
  },

  [types.SET_PAGE](state, page) {
    state.pageInfo.page = page;
  },
};
