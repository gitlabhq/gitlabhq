import * as types from './mutation_types';
import projectMutations from './mutations/project';
import fileMutations from './mutations/file';
import treeMutations from './mutations/tree';
import branchMutations from './mutations/branch';

export default {
  [types.SET_INITIAL_DATA](state, data) {
    Object.assign(state, data);
  },
  [types.SET_PREVIEW_MODE](state) {
    Object.assign(state, {
      currentBlobView: 'repo-preview',
    });
  },
  [types.SET_EDIT_MODE](state) {
    Object.assign(state, {
      currentBlobView: 'repo-editor',
    });
  },
  [types.TOGGLE_LOADING](state, { entry, forceValue = undefined }) {
    Object.assign(entry, {
      loading: forceValue !== undefined ? forceValue : !entry.loading,
    });
  },
  [types.TOGGLE_EDIT_MODE](state) {
    Object.assign(state, {
      editMode: !state.editMode,
    });
  },
  [types.SET_LEFT_PANEL_COLLAPSED](state, collapsed) {
    Object.assign(state, {
      leftPanelCollapsed: collapsed,
    });
  },
  [types.SET_RIGHT_PANEL_COLLAPSED](state, collapsed) {
    Object.assign(state, {
      rightPanelCollapsed: collapsed,
    });
  },
  [types.SET_RESIZING_STATUS](state, resizing) {
    Object.assign(state, {
      panelResizing: resizing,
    });
  },
  [types.SET_LAST_COMMIT_DATA](state, { entry, lastCommit }) {
    Object.assign(entry.lastCommit, {
      id: lastCommit.commit.id,
      url: lastCommit.commit_path,
      message: lastCommit.commit.message,
      author: lastCommit.commit.author_name,
      updatedAt: lastCommit.commit.authored_date,
    });
  },
  [types.SET_LAST_COMMIT_MSG](state, lastCommitMsg) {
    Object.assign(state, {
      lastCommitMsg,
    });
  },
  [types.UPDATE_VIEWER](state, viewer) {
    Object.assign(state, {
      viewer,
    });
  },
  [types.UPDATE_DELAY_VIEWER_CHANGE](state, delayViewerUpdated) {
    Object.assign(state, {
      delayViewerUpdated,
    });
  },
  ...projectMutations,
  ...fileMutations,
  ...treeMutations,
  ...branchMutations,
};
