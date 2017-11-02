import * as types from './mutation_types';
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
  [types.TOGGLE_LOADING](state, entry) {
    Object.assign(entry, {
      loading: !entry.loading,
    });
  },
  [types.TOGGLE_EDIT_MODE](state) {
    Object.assign(state, {
      editMode: !state.editMode,
    });
  },
  [types.TOGGLE_DISCARD_POPUP](state, discardPopupOpen) {
    Object.assign(state, {
      discardPopupOpen,
    });
  },
  [types.SET_COMMIT_REF](state, ref) {
    Object.assign(state, {
      currentRef: ref,
    });
  },
  [types.SET_ROOT](state, isRoot) {
    Object.assign(state, {
      isRoot,
      isInitialRoot: isRoot,
    });
  },
  [types.SET_PREVIOUS_URL](state, previousUrl) {
    Object.assign(state, {
      previousUrl,
    });
  },
  [types.SET_LAST_COMMIT_DATA](state, { entry, lastCommit }) {
    Object.assign(entry.lastCommit, {
      url: lastCommit.commit_path,
      message: lastCommit.commit.message,
      updatedAt: lastCommit.commit.authored_date,
    });
  },
  ...fileMutations,
  ...treeMutations,
  ...branchMutations,
};
