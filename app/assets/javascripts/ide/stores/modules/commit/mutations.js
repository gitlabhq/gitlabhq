import * as types from './mutation_types';
import consts from './constants';

export default {
  [types.UPDATE_COMMIT_MESSAGE](state, commitMessage) {
    Object.assign(state, {
      commitMessage,
    });
  },
  [types.UPDATE_COMMIT_ACTION](state, { commitAction, currentMergeRequest }) {
    Object.assign(state, {
      commitAction,
      shouldCreateMR:
        commitAction === consts.COMMIT_TO_CURRENT_BRANCH && currentMergeRequest
          ? false
          : state.shouldCreateMR,
    });
  },
  [types.UPDATE_NEW_BRANCH_NAME](state, newBranchName) {
    Object.assign(state, {
      newBranchName,
    });
  },
  [types.UPDATE_LOADING](state, submitCommitLoading) {
    Object.assign(state, {
      submitCommitLoading,
    });
  },
  [types.TOGGLE_SHOULD_CREATE_MR](state) {
    Object.assign(state, {
      shouldCreateMR: !state.shouldCreateMR,
    });
  },
};
