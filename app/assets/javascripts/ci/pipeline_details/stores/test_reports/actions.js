import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import * as types from './mutation_types';
import { SUITE_FETCH_CONCURRENCY } from './constants';

const fetchSuiteCases = (state, index) => {
  const { build_ids: buildIds = [] } = state.testReports?.test_suites?.[index] || {};

  return axios
    .get(state.suiteEndpoint, { params: { build_ids: buildIds } })
    .then(({ data }) => data);
};

export const fetchSummary = ({ state, commit, dispatch }) => {
  dispatch('toggleLoading');

  return axios
    .get(state.summaryEndpoint)
    .then(({ data }) => {
      commit(types.SET_SUMMARY, data);
    })
    .catch(() => {
      createAlert({
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

  return axios
    .get(state.suiteEndpoint, { params: { build_ids } })
    .then(({ data }) => commit(types.SET_SUITE, { suite: data, index }))
    .catch((error) => commit(types.SET_SUITE_ERROR, error))
    .finally(() => {
      dispatch('toggleLoading');
    });
};

// Loads every suite's test cases (once) so a global search can filter across
// all jobs client-side. Suites already fully loaded are skipped, and requests
// run with bounded concurrency to avoid a burst of one request per suite.
export const fetchAllSuites = ({ state, commit }) => {
  if (state.hasFetchedAllSuites || state.isLoadingAllSuites) {
    return Promise.resolve();
  }

  const suites = state.testReports?.test_suites || [];
  const results = suites.slice();
  const queue = suites.map((suite, index) => index).filter((index) => !suites[index].hasFullSuite);
  let hasSuiteFetchError = false;

  commit(types.SET_LOADING_ALL_SUITES, true);

  const worker = () => {
    if (queue.length === 0) {
      return Promise.resolve();
    }

    const index = queue.shift();
    return fetchSuiteCases(state, index)
      .then((data) => {
        results[index] = { ...data, hasFullSuite: true };
      })
      .catch(() => {
        // Leave the summary-only entry in place; its cases just won't be
        // searchable. A single failing suite must not break the whole search.
        hasSuiteFetchError = true;
      })
      .then(worker);
  };

  const workers = Array.from({ length: Math.min(SUITE_FETCH_CONCURRENCY, queue.length) }, worker);

  return Promise.all(workers)
    .then(() => {
      commit(types.SET_ALL_SUITES, results);
      commit(types.SET_FETCHED_ALL_SUITES, true);

      if (hasSuiteFetchError) {
        createAlert({
          message: s__(
            'TestReports|Some test suites could not be loaded and are excluded from search results.',
          ),
        });
      }
    })
    .catch(() => {
      createAlert({
        message: s__('TestReports|There was an error fetching the test cases.'),
      });
    })
    .finally(() => {
      commit(types.SET_LOADING_ALL_SUITES, false);
    });
};

export const setSearchTerm = ({ commit }, searchTerm) => commit(types.SET_SEARCH_TERM, searchTerm);
export const setSearchScope = ({ commit }, scope) => commit(types.SET_SEARCH_SCOPE, scope);

export const setPage = ({ commit }, page) => commit(types.SET_PAGE, page);
export const setSelectedSuiteIndex = ({ commit }, data) =>
  commit(types.SET_SELECTED_SUITE_INDEX, data);
export const removeSelectedSuiteIndex = ({ commit }) =>
  commit(types.SET_SELECTED_SUITE_INDEX, null);
export const toggleLoading = ({ commit }) => commit(types.TOGGLE_LOADING);
