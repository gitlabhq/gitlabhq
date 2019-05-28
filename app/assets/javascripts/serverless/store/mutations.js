import * as types from './mutation_types';

export default {
  [types.REQUEST_FUNCTIONS_LOADING](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_FUNCTIONS_SUCCESS](state, data) {
    state.functions = data;
    state.isLoading = false;
    state.hasFunctionData = true;
  },
  [types.RECEIVE_FUNCTIONS_NODATA_SUCCESS](state) {
    state.isLoading = false;
    state.hasFunctionData = false;
  },
  [types.RECEIVE_FUNCTIONS_ERROR](state, error) {
    state.error = error;
    state.hasFunctionData = false;
    state.isLoading = false;
  },
  [types.RECEIVE_METRICS_SUCCESS](state, data) {
    state.isLoading = false;
    state.hasPrometheusData = true;
    state.graphData = data;
  },
  [types.RECEIVE_METRICS_NODATA_SUCCESS](state) {
    state.isLoading = false;
    state.hasPrometheusData = false;
  },
  [types.RECEIVE_METRICS_ERROR](state, error) {
    state.hasPrometheusData = false;
    state.error = error;
  },
  [types.RECEIVE_METRICS_NO_PROMETHEUS](state) {
    state.hasPrometheusData = false;
    state.hasPrometheus = false;
  },
};
