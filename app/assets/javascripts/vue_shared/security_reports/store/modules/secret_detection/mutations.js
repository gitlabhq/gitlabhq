import { parseDiff } from '~/vue_shared/security_reports/store/utils';
import * as types from './mutation_types';

export default {
  [types.SET_DIFF_ENDPOINT](state, path) {
    state.paths.diffEndpoint = path;
  },

  [types.REQUEST_DIFF](state) {
    state.isLoading = true;
  },

  [types.RECEIVE_DIFF_SUCCESS](state, { diff, enrichData }) {
    const { added, fixed, existing } = parseDiff(diff, enrichData);
    const baseReportOutofDate = diff.base_report_out_of_date || false;
    const hasBaseReport = Boolean(diff.base_report_created_at);

    state.isLoading = false;
    state.newIssues = added;
    state.resolvedIssues = fixed;
    state.allIssues = existing;
    state.baseReportOutofDate = baseReportOutofDate;
    state.hasBaseReport = hasBaseReport;
  },

  [types.RECEIVE_DIFF_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },
};
