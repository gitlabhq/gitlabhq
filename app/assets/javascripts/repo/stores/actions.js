import Vue from 'vue';
import flash from '../../flash';
import service from '../services';
import * as types from './mutation_types';

export const redirectToUrl = (_, url) => gl.utils.visitUrl(url);

export const setInitialData = ({ commit }, data) => commit(types.SET_INITIAL_DATA, data);

export const closeDiscardPopup = ({ commit }) => commit(types.TOGGLE_DISCARD_POPUP, false);

export const discardAllChanges = ({ commit, getters, dispatch }) => {
  const changedFiles = getters.changedFiles;

  changedFiles.forEach((file) => {
    commit(types.DISCARD_FILE_CHANGES, file);

    if (file.tempFile) {
      dispatch('closeFile', { file, force: true });
    }
  });
};

export const closeAllFiles = ({ state, dispatch }) => {
  state.openFiles.forEach(file => dispatch('closeFile', { file }));
};

export const toggleEditMode = ({ state, commit, getters, dispatch }, force = false) => {
  const changedFiles = getters.changedFiles;

  if (changedFiles.length && !force) {
    commit(types.TOGGLE_DISCARD_POPUP, true);
  } else {
    commit(types.TOGGLE_EDIT_MODE);
    commit(types.TOGGLE_DISCARD_POPUP, false);
    dispatch('toggleBlobView');

    if (!state.editMode) {
      dispatch('discardAllChanges');
    }
  }
};

export const toggleBlobView = ({ commit, state }) => {
  if (state.editMode) {
    commit(types.SET_EDIT_MODE);
  } else {
    commit(types.SET_PREVIEW_MODE);
  }
};

export const checkCommitStatus = ({ state }) => service.getBranchData(
  state.project.id,
  state.currentBranch,
)
  .then((data) => {
    const { id } = data.commit;

    if (state.currentRef !== id) {
      return true;
    }

    return false;
  })
  .catch(() => flash('Error checking branch data. Please try again.'));

export const commitChanges = ({ commit, state, dispatch, getters }, { payload, newMr }) =>
  service.commit(state.project.id, payload)
  .then((data) => {
    const { branch } = payload;
    if (!data.short_id) {
      flash(data.message);
      return;
    }

    const lastCommit = {
      commit_path: `${state.project.url}/commit/${data.id}`,
      commit: {
        message: data.message,
        authored_date: data.committed_date,
      },
    };

    flash(`Your changes have been committed. Commit ${data.short_id} with ${data.stats.additions} additions, ${data.stats.deletions} deletions.`, 'notice');

    if (newMr) {
      dispatch('redirectToUrl', `${state.endpoints.newMergeRequestUrl}${branch}`);
    } else {
      commit(types.SET_COMMIT_REF, data.id);

      getters.changedFiles.forEach((entry) => {
        commit(types.SET_LAST_COMMIT_DATA, {
          entry,
          lastCommit,
        });
      });

      dispatch('discardAllChanges');
      dispatch('closeAllFiles');
      dispatch('toggleEditMode');

      window.scrollTo(0, 0);
    }
  })
  .catch(() => flash('Error committing changes. Please try again.'));

export const createTempEntry = ({ state, dispatch }, { name, type, content = '', base64 = false }) => {
  if (type === 'tree') {
    dispatch('createTempTree', name);
  } else if (type === 'blob') {
    dispatch('createTempFile', {
      tree: state,
      name,
      base64,
      content,
    });
  }
};

export const popHistoryState = ({ state, dispatch, getters }) => {
  const treeList = getters.treeList;
  const tree = treeList.find(file => file.url === state.previousUrl);

  if (!tree) return;

  if (tree.type === 'tree') {
    dispatch('toggleTreeOpen', { endpoint: tree.url, tree });
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

export * from './actions/tree';
export * from './actions/file';
export * from './actions/branch';
