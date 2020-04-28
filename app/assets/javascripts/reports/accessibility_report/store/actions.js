import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';
import { parseAccessibilityReport, compareAccessibilityReports } from './utils';
import { s__ } from '~/locale';

export const setEndpoints = ({ commit }, { baseEndpoint, headEndpoint }) =>
  commit(types.SET_ENDPOINTS, { baseEndpoint, headEndpoint });

export const fetchReport = ({ state, dispatch, commit }) => {
  commit(types.REQUEST_REPORT);

  // If we don't have both endpoints, throw an error.
  if (!state.baseEndpoint || !state.headEndpoint) {
    commit(
      types.RECEIVE_REPORT_ERROR,
      s__('AccessibilityReport|Accessibility report artifact not found'),
    );
    return;
  }

  Promise.all([
    axios.get(state.baseEndpoint).then(response => ({
      ...response.data,
      isHead: false,
    })),
    axios.get(state.headEndpoint).then(response => ({
      ...response.data,
      isHead: true,
    })),
  ])
    .then(responses => dispatch('receiveReportSuccess', responses))
    .catch(() =>
      commit(
        types.RECEIVE_REPORT_ERROR,
        s__('AccessibilityReport|Failed to retrieve accessibility report'),
      ),
    );
};

export const receiveReportSuccess = ({ commit }, responses) => {
  const parsedReports = responses.map(response => ({
    isHead: response.isHead,
    issues: parseAccessibilityReport(response),
  }));
  const report = compareAccessibilityReports(parsedReports);
  commit(types.RECEIVE_REPORT_SUCCESS, report);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
