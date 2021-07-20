import { escape } from 'lodash';
import createFlash from '~/flash';
import { __, sprintf } from '~/locale';
import api from '../../../api';
import service from '../../services';
import * as types from '../mutation_types';

export const getProjectData = ({ commit, state }, { namespace, projectId, force = false } = {}) =>
  new Promise((resolve, reject) => {
    if (!state.projects[`${namespace}/${projectId}`] || force) {
      commit(types.TOGGLE_LOADING, { entry: state });
      service
        .getProjectData(namespace, projectId)
        .then((res) => res.data)
        .then((data) => {
          commit(types.TOGGLE_LOADING, { entry: state });
          commit(types.SET_PROJECT, { projectPath: `${namespace}/${projectId}`, project: data });
          commit(types.SET_CURRENT_PROJECT, `${namespace}/${projectId}`);
          resolve(data);
        })
        .catch(() => {
          createFlash({
            message: __('Error loading project data. Please try again.'),
            fadeTransition: false,
            addBodyClass: true,
          });
          reject(new Error(`Project not loaded ${namespace}/${projectId}`));
        });
    } else {
      resolve(state.projects[`${namespace}/${projectId}`]);
    }
  });

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
      createFlash({
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
  } else if (getters.emptyRepo) {
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
