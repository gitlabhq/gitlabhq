import * as types from './mutation_types';

export default {
  [types.PUSH](state, fullPath) {
    state.fullPath = fullPath;
  },
};
