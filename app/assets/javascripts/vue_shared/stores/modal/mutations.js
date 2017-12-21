import * as types from './mutation_types'

export default {
  [types.HIDE](state) {
    state.isVisible = false;
  },
  [types.SHOW](state) {
    state.isVisible = true;
  },
};
