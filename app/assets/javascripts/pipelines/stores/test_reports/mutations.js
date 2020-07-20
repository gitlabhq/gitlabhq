import * as types from './mutation_types';

export default {
  [types.SET_REPORTS](state, testReports) {
    Object.assign(state, { testReports, hasFullReport: true });
  },

  [types.SET_SELECTED_SUITE_INDEX](state, selectedSuiteIndex) {
    Object.assign(state, { selectedSuiteIndex });
  },

  [types.SET_SUMMARY](state, summary) {
    Object.assign(state, { testReports: { ...state.testReports, ...summary } });
  },

  [types.TOGGLE_LOADING](state) {
    Object.assign(state, { isLoading: !state.isLoading });
  },
};
