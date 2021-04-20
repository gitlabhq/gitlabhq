import * as types from './mutation_types';
import { countRecentlyFailedTests, formatFilePath } from './utils';

export default {
  [types.SET_PATHS](state, { endpoint, headBlobPath }) {
    state.endpoint = endpoint;
    state.headBlobPath = headBlobPath;
  },
  [types.REQUEST_REPORTS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_REPORTS_SUCCESS](state, response) {
    state.hasError = response.suites.some((suite) => suite.status === 'error');

    state.isLoading = false;

    state.summary.total = response.summary.total;
    state.summary.resolved = response.summary.resolved;
    state.summary.failed = response.summary.failed;
    state.summary.errored = response.summary.errored;
    state.summary.recentlyFailed = countRecentlyFailedTests(response.suites);

    state.status = response.status;
    state.reports = response.suites;

    state.reports.forEach((report, i) => {
      if (!state.reports[i].summary) return;
      state.reports[i].summary.recentlyFailed = countRecentlyFailedTests(report);
    });
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
      recentlyFailed: 0,
    };
    state.status = null;
  },
  [types.SET_ISSUE_MODAL_DATA](state, payload) {
    const { issue } = payload;
    state.modal.title = issue.name;

    Object.keys(issue).forEach((key) => {
      if (Object.prototype.hasOwnProperty.call(state.modal.data, key)) {
        state.modal.data[key] = {
          ...state.modal.data[key],
          value: issue[key],
        };
      }
    });

    if (issue.file) {
      state.modal.data.filename.value = {
        text: issue.file,
        path: `${state.headBlobPath}/${formatFilePath(issue.file)}`,
      };
    }

    state.modal.open = true;
  },
  [types.RESET_ISSUE_MODAL_DATA](state) {
    state.modal.open = false;

    // Resetting modal data
    state.modal.title = null;
    Object.keys(state.modal.data).forEach((key) => {
      state.modal.data[key] = {
        ...state.modal.data[key],
        value: null,
      };
    });
  },
};
