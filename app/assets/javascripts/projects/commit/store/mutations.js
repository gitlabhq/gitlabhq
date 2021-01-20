import * as types from './mutation_types';

export default {
  [types.REQUEST_BRANCHES](state) {
    state.isFetching = true;
  },

  [types.RECEIVE_BRANCHES_SUCCESS](state, branches) {
    state.isFetching = false;
    state.branches = branches;
    state.branches.unshift(state.branch);
  },

  [types.CLEAR_MODAL](state) {
    state.branch = state.defaultBranch;
  },

  [types.SET_BRANCH](state, branch) {
    state.branch = branch;
  },

  [types.SET_SELECTED_BRANCH](state, branch) {
    state.selectedBranch = branch;
  },
};
