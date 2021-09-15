import * as types from './mutation_types';

export default {
  [types.SET_SEARCH](state, value) {
    state.search = value;
  },
};
