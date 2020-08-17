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

  [types.RECEIVE_REPOS_SUCCESS](
    state,
    { importedProjects, providerRepos, incompatibleRepos = [] },
  ) {
    // Normalizing structure to support legacy backend format
    // See https://gitlab.com/gitlab-org/gitlab/-/issues/27370#note_379034091 for details

    state.isLoadingRepos = false;

    state.repositories = [
      ...importedProjects.map(({ importSource, providerLink, importStatus, ...project }) => ({
        importSource: {
          id: `finished-${project.id}`,
          fullName: importSource,
          sanitizedName: project.name,
          providerLink,
        },
        importStatus,
        importedProject: project,
      })),
      ...providerRepos.map(project => ({
        importSource: project,
        importStatus: STATUSES.NONE,
        importedProject: null,
      })),
      ...incompatibleRepos.map(project => ({
        importSource: { ...project, incompatible: true },
        importStatus: STATUSES.NONE,
        importedProject: null,
      })),
    ];
  },

  [types.RECEIVE_REPOS_ERROR](state) {
    state.isLoadingRepos = false;
  },

  [types.REQUEST_IMPORT](state, { repoId, importTarget }) {
    const existingRepo = state.repositories.find(r => r.importSource.id === repoId);
    existingRepo.importStatus = STATUSES.SCHEDULING;
    existingRepo.importedProject = {
      fullPath: `/${importTarget.targetNamespace}/${importTarget.newName}`,
    };
  },

  [types.RECEIVE_IMPORT_SUCCESS](state, { importedProject, repoId }) {
    const { importStatus, ...project } = importedProject;

    const existingRepo = state.repositories.find(r => r.importSource.id === repoId);
    existingRepo.importStatus = importStatus;
    existingRepo.importedProject = project;
  },

  [types.RECEIVE_IMPORT_ERROR](state, repoId) {
    const existingRepo = state.repositories.find(r => r.importSource.id === repoId);
    existingRepo.importStatus = STATUSES.NONE;
    existingRepo.importedProject = null;
  },

  [types.RECEIVE_JOBS_SUCCESS](state, updatedProjects) {
    updatedProjects.forEach(updatedProject => {
      const repo = state.repositories.find(p => p.importedProject?.id === updatedProject.id);
      if (repo) {
        repo.importStatus = updatedProject.importStatus;
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
};
