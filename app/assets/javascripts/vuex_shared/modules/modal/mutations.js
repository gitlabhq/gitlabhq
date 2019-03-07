import * as types from './mutation_types';

export default {
  [types.SHOW](state) {
    state.isVisible = true;
  },
  [types.HIDE](state) {
    state.isVisible = false;
  },
  [types.OPEN](state, data) {
    state.data = data;
    state.isVisible = true;
  },
  [types.CLOSE](state) {
    state.data = null;
    state.isVisible = false;
  },
};
