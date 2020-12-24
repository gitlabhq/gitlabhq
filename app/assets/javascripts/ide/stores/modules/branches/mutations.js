import * as types from './mutation_types';

export default {
  [types.REQUEST_BRANCHES](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_BRANCHES_ERROR](state) {
    state.isLoading = false;
  },
  [types.RECEIVE_BRANCHES_SUCCESS](state, data) {
    state.isLoading = false;
    state.branches = data.map((branch) => ({
      name: branch.name,
      committedDate: branch.commit.committed_date,
    }));
  },
  [types.RESET_BRANCHES](state) {
    state.branches = [];
  },
};
