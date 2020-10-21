import * as types from './mutation_types';

export default {
  [types.CLOSE_DRAWER](state) {
    state.open = false;
  },
  [types.OPEN_DRAWER](state) {
    state.open = true;
  },
  [types.SET_FEATURES](state, data) {
    state.features = data;
  },
};
