import * as types from './mutation_types';

export default {
  [types.SET_LOADING_STATE](state, value) {
    state.loading = value;
  },
  [types.SET_CHART_DATA](state, chartData) {
    Object.assign(state, {
      chartData,
    });
  },
  [types.SET_ACTIVE_BRANCH](state, branch) {
    Object.assign(state, {
      branch,
    });
  },
};
