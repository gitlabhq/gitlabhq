import * as types from './mutation_types';

export default {
  [types.SET_ALERTS](state, alerts) {
    state.alerts = alerts;
  },
  [types.SET_LOADING](state, loading) {
    state.loading = loading;
  },
};
