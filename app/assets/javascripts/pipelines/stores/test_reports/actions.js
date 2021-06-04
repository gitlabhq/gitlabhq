import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import * as types from './mutation_types';

export const fetchSummary = ({ state, commit, dispatch }) => {
  dispatch('toggleLoading');

  return axios
    .get(state.summaryEndpoint)
    .then(({ data }) => {
      commit(types.SET_SUMMARY, data);
    })
    .catch(() => {
      createFlash({
        message: s__('TestReports|There was an error fetching the summary.'),
      });
    })
    .finally(() => {
      dispatch('toggleLoading');
    });
};

export const fetchTestSuite = ({ state, commit, dispatch }, index) => {
  const { hasFullSuite } = state.testReports?.test_suites?.[index] || {};
  // We don't need to fetch the suite if we have the information already
  if (hasFullSuite) {
    return Promise.resolve();
  }

  dispatch('toggleLoading');

  const { build_ids = [] } = state.testReports?.test_suites?.[index] || {};
  // Replacing `/:suite_name.json` with the name of the suite. Including the extra characters
  // to ensure that we replace exactly the template part of the URL string

  return axios
    .get(state.suiteEndpoint, { params: { build_ids } })
    .then(({ data }) => commit(types.SET_SUITE, { suite: data, index }))
    .catch(() => {
      createFlash({
        message: s__('TestReports|There was an error fetching the test suite.'),
      });
    })
    .finally(() => {
      dispatch('toggleLoading');
    });
};

export const setPage = ({ commit }, page) => commit(types.SET_PAGE, page);
export const setSelectedSuiteIndex = ({ commit }, data) =>
  commit(types.SET_SELECTED_SUITE_INDEX, data);
export const removeSelectedSuiteIndex = ({ commit }) =>
  commit(types.SET_SELECTED_SUITE_INDEX, null);
export const toggleLoading = ({ commit }) => commit(types.TOGGLE_LOADING);
