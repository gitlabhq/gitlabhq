import * as types from './mutation_types';

export default {
  [types.UPDATE_COMMIT_MESSAGE](state, commitMessage) {
    Object.assign(state, {
      commitMessage,
    });
  },
  [types.UPDATE_COMMIT_ACTION](state, { commitAction }) {
    Object.assign(state, { commitAction });
  },
  [types.UPDATE_NEW_BRANCH_NAME](state, newBranchName) {
    Object.assign(state, { newBranchName });
  },
  [types.UPDATE_LOADING](state, submitCommitLoading) {
    Object.assign(state, {
      submitCommitLoading,
    });
  },
  [types.TOGGLE_SHOULD_CREATE_MR](state, shouldCreateMR) {
    Object.assign(state, {
      shouldCreateMR: shouldCreateMR === undefined ? !state.shouldCreateMR : shouldCreateMR,
    });
  },
  [types.CLEAR_ERROR](state) {
    state.commitError = null;
  },
  [types.SET_ERROR](state, error) {
    state.commitError = error;
  },
};
