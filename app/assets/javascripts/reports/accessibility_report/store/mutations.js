import * as types from './mutation_types';

export default {
  [types.REQUEST_REPORT](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_REPORT_SUCCESS](state, report) {
    state.hasError = false;
    state.isLoading = false;
    state.report = report;
  },
  [types.RECEIVE_REPORT_ERROR](state, message) {
    state.isLoading = false;
    state.hasError = true;
    state.errorMessage = message;
    state.report = {};
  },
};
