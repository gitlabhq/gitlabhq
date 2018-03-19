import Vue from 'vue';
import { visitUrl } from '~/lib/utils/url_utility';
import * as types from './mutation_types';

export const redirectToUrl = (_, url) => visitUrl(url);

export const setInitialData = ({ commit }, data) =>
  commit(types.SET_INITIAL_DATA, data);

export const discardAllChanges = ({ state, commit, dispatch }) => {
  state.changedFiles.forEach((file) => {
    commit(types.DISCARD_FILE_CHANGES, file);

    if (file.tempFile) {
      dispatch('closeFile', file);
    }
  });

  commit(types.REMOVE_ALL_CHANGES_FILES);
};

export const closeAllFiles = ({ state, dispatch }) => {
  state.openFiles.forEach(file => dispatch('closeFile', file));
};

export const toggleEditMode = ({ commit, dispatch }) => {
  commit(types.TOGGLE_EDIT_MODE);
  dispatch('toggleBlobView');
};

export const toggleBlobView = ({ commit, state }) => {
  if (state.editMode) {
    commit(types.SET_EDIT_MODE);
  } else {
    commit(types.SET_PREVIEW_MODE);
  }
};

export const setPanelCollapsedStatus = ({ commit }, { side, collapsed }) => {
  if (side === 'left') {
    commit(types.SET_LEFT_PANEL_COLLAPSED, collapsed);
  } else {
    commit(types.SET_RIGHT_PANEL_COLLAPSED, collapsed);
  }
};

export const setResizingStatus = ({ commit }, resizing) => {
  commit(types.SET_RESIZING_STATUS, resizing);
};

export const createTempEntry = (
  { state, dispatch },
  { projectId, branchId, parent, name, type, content = '', base64 = false },
) => {
  const selectedParent = parent || state.trees[`${projectId}/${branchId}`];
  if (type === 'tree') {
    dispatch('createTempTree', {
      projectId,
      branchId,
      parent: selectedParent,
      name,
    });
  } else if (type === 'blob') {
    dispatch('createTempFile', {
      projectId,
      branchId,
      parent: selectedParent,
      name,
      base64,
      content,
    });
  }
};

export const scrollToTab = () => {
  Vue.nextTick(() => {
    const tabs = document.getElementById('tabs');

    if (tabs) {
      const tabEl = tabs.querySelector('.active .repo-tab');

      tabEl.focus();
    }
  });
};

export const updateViewer = ({ commit }, viewer) => {
  commit(types.UPDATE_VIEWER, viewer);
};

export const updateDelayViewerUpdated = ({ commit }, delay) => {
  commit(types.UPDATE_DELAY_VIEWER_CHANGE, delay);
};

export * from './actions/tree';
export * from './actions/file';
export * from './actions/project';
export * from './actions/branch';
