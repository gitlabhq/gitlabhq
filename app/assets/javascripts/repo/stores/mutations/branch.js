import * as types from '../mutation_types';

export default {
  [types.SET_CURRENT_BRANCH](state, currentBranch) {
    Object.assign(state, {
      currentBranch,
    });
  },
};
