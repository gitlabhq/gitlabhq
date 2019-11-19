import * as types from './mutation_types';

export default {
  [types.SET_ENDPOINT](state, endpoint) {
    Object.assign(state, { endpoint });
  },

  [types.SET_REPORTS](state, testReports) {
    Object.assign(state, { testReports });
  },

  [types.SET_SELECTED_SUITE](state, selectedSuite) {
    Object.assign(state, { selectedSuite });
  },

  [types.TOGGLE_LOADING](state) {
    Object.assign(state, { isLoading: !state.isLoading });
  },
};
