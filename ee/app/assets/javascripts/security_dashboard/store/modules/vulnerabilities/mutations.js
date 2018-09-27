import * as types from './mutation_types';

export default {
  [types.SET_LOADING](state, payload) {
    state.isLoading = payload;
  },
  [types.SET_PAGINATION](state, payload) {
    state.pageInfo = payload;
  },
  [types.SET_VULNERABILITIES](state, payload) {
    state.vulnerabilities = payload;
  },
};
