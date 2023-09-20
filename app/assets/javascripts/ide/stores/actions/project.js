import { escape } from 'lodash';
import { createAlert } from '~/alert';
import { __, sprintf } from '~/locale';
import { logError } from '~/lib/logger';
import api from '~/api';
import service from '../../services';
import * as types from '../mutation_types';

const ERROR_LOADING_PROJECT = __('Error loading project data. Please try again.');

const errorFetchingData = (e) => {
  logError(ERROR_LOADING_PROJECT, e);

  createAlert({
    message: ERROR_LOADING_PROJECT,
    fadeTransition: false,
    addBodyClass: true,
  });
};

export const setProject = ({ commit }, { project } = {}) => {
  if (!project) {
    return;
  }
  const projectPath = project.path_with_namespace;
  commit(types.SET_PROJECT, { projectPath, project });
  commit(types.SET_CURRENT_PROJECT, projectPath);
};

export const fetchProjectPermissions = ({ commit, state }) => {
  const projectPath = state.currentProjectId;
  if (!projectPath) {
    return undefined;
  }
  return service
    .getProjectPermissionsData(projectPath)
    .then((permissions) => {
      commit(types.UPDATE_PROJECT, { projectPath, props: permissions });
    })
    .catch(errorFetchingData);
};

export const refreshLastCommitData = ({ commit }, { projectId, branchId } = {}) =>
  service
    .getBranchData(projectId, branchId)
    .then(({ data }) => {
      commit(types.SET_BRANCH_COMMIT, {
        projectId,
        branchId,
        commit: data.commit,
      });
    })
    .catch((e) => {
      createAlert({
        message: __('Error loading last commit.'),
        fadeTransition: false,
        addBodyClass: true,
      });
      throw e;
    });

export const createNewBranchFromDefault = ({ state, dispatch, getters }, branch) =>
  api
    .createBranch(state.currentProjectId, {
      ref: getters.currentProject.default_branch,
      branch,
    })
    .then(() => {
      dispatch('setErrorMessage', null);
      window.location.reload();
    })
    .catch(() => {
      dispatch('setErrorMessage', {
        text: __('An error occurred creating the new branch.'),
        action: (payload) => dispatch('createNewBranchFromDefault', payload),
        actionText: __('Please try again'),
        actionPayload: branch,
      });
    });

export const showBranchNotFoundError = ({ dispatch }, branchId) => {
  dispatch('setErrorMessage', {
    text: sprintf(
      __("Branch %{branchName} was not found in this project's repository."),
      {
        branchName: `<strong>${escape(branchId)}</strong>`,
      },
      false,
    ),
    action: (payload) => dispatch('createNewBranchFromDefault', payload),
    actionText: __('Create branch'),
    actionPayload: branchId,
  });
};

export const loadEmptyBranch = ({ commit, state }, { projectId, branchId }) => {
  const treePath = `${projectId}/${branchId}`;
  const currentTree = state.trees[`${projectId}/${branchId}`];

  // If we already have a tree, let's not recreate an empty one
  if (currentTree) {
    return;
  }

  commit(types.CREATE_TREE, { treePath });
  commit(types.TOGGLE_LOADING, {
    entry: state.trees[treePath],
    forceValue: false,
  });
};

export const loadFile = ({ dispatch, state }, { basePath }) => {
  if (basePath) {
    const path = basePath.slice(-1) === '/' ? basePath.slice(0, -1) : basePath;
    const treeEntryKey = Object.keys(state.entries).find(
      (key) => key === path && !state.entries[key].pending,
    );
    const treeEntry = state.entries[treeEntryKey];

    if (treeEntry) {
      dispatch('handleTreeEntryAction', treeEntry);
    } else {
      dispatch('createTempEntry', {
        name: path,
        type: 'blob',
      });
    }
  }
};

export const loadBranch = ({ dispatch, getters, state }, { projectId, branchId }) => {
  const currentProject = state.projects[projectId];

  if (currentProject?.branches?.[branchId]) {
    return Promise.resolve();
  }
  if (getters.emptyRepo) {
    return dispatch('loadEmptyBranch', { projectId, branchId });
  }

  return dispatch('getBranchData', {
    projectId,
    branchId,
  })
    .then(() => {
      dispatch('getMergeRequestsForBranch', {
        projectId,
        branchId,
      });

      const branch = getters.findBranch(projectId, branchId);

      return dispatch('getFiles', {
        projectId,
        branchId,
        ref: branch.commit.id,
      });
    })
    .catch((err) => {
      dispatch('showBranchNotFoundError', branchId);
      throw err;
    });
};

export const openBranch = ({ dispatch }, { projectId, branchId, basePath }) => {
  dispatch('setCurrentBranchId', branchId);

  return dispatch('loadBranch', { projectId, branchId })
    .then(() => dispatch('loadFile', { basePath }))
    .catch(
      () =>
        new Error(
          sprintf(
            __('An error occurred while getting files for - %{branchId}'),
            {
              branchId: `<strong>${escape(projectId)}/${escape(branchId)}</strong>`,
            },
            false,
          ),
        ),
    );
};
