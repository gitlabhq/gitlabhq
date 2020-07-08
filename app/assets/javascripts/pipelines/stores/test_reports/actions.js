import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';
import createFlash from '~/flash';
import { s__ } from '~/locale';

export const fetchSummary = ({ state, commit }) => {
  return axios
    .get(state.summaryEndpoint)
    .then(({ data }) => {
      commit(types.SET_SUMMARY, data);

      // Set the tab counter badge to total_count
      // This is temporary until we can server-side render that count number
      // (see https://gitlab.com/gitlab-org/gitlab/-/issues/223134)
      if (data.total_count !== undefined) {
        document.querySelector('.js-test-report-badge-counter').innerHTML = data.total_count;
      }
    })
    .catch(() => {
      createFlash(s__('TestReports|There was an error fetching the summary.'));
    });
};

export const fetchFullReport = ({ state, commit, dispatch }) => {
  dispatch('toggleLoading');

  return axios
    .get(state.fullReportEndpoint)
    .then(({ data }) => commit(types.SET_REPORTS, data))
    .catch(() => {
      createFlash(s__('TestReports|There was an error fetching the test reports.'));
    })
    .finally(() => {
      dispatch('toggleLoading');
    });
};

export const setSelectedSuiteIndex = ({ commit }, data) =>
  commit(types.SET_SELECTED_SUITE_INDEX, data);
export const removeSelectedSuiteIndex = ({ commit }) =>
  commit(types.SET_SELECTED_SUITE_INDEX, null);
export const toggleLoading = ({ commit }) => commit(types.TOGGLE_LOADING);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
