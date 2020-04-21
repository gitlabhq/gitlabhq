import * as types from './mutation_types';

export default {
  [types.SET_ENDPOINT](state, endpoint) {
    state.endpoint = endpoint;
  },
  [types.REQUEST_REPORTS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_REPORTS_SUCCESS](state, response) {
    state.hasError = response.suites.some(suite => suite.status === 'error');

    state.isLoading = false;

    state.summary.total = response.summary.total;
    state.summary.resolved = response.summary.resolved;
    state.summary.failed = response.summary.failed;
    state.summary.errored = response.summary.errored;

    state.status = response.status;
    state.reports = response.suites;
  },
  [types.RECEIVE_REPORTS_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;

    state.reports = [];
    state.summary = {
      total: 0,
      resolved: 0,
      failed: 0,
      errored: 0,
    };
    state.status = null;
  },
  [types.SET_ISSUE_MODAL_DATA](state, payload) {
    state.modal.title = payload.issue.name;

    Object.keys(payload.issue).forEach(key => {
      if (Object.prototype.hasOwnProperty.call(state.modal.data, key)) {
        state.modal.data[key] = {
          ...state.modal.data[key],
          value: payload.issue[key],
        };
      }
    });
  },
};
