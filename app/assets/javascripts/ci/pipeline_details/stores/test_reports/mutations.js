import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import * as types from './mutation_types';

export default {
  [types.SET_PAGE](state, page) {
    Object.assign(state, {
      pageInfo: Object.assign(state.pageInfo, {
        page,
      }),
    });
  },

  [types.SET_SUITE](state, { suite = {}, index = null }) {
    state.testReports.test_suites[index] = { ...suite, hasFullSuite: true };
  },

  [types.SET_SUITE_ERROR](state, error) {
    const errorMessage = error.response?.data?.errors;

    if (errorMessage) {
      state.errorMessage = errorMessage;
    } else {
      createAlert({
        message: s__('TestReports|There was an error fetching the test suite.'),
      });
    }
  },

  [types.SET_ALL_SUITES](state, suites) {
    // Reassign the whole array (rather than mutating indices) so the change is
    // reactive and the global search getters recompute once loading finishes.
    state.testReports = { ...state.testReports, test_suites: suites };
  },

  [types.SET_SEARCH_TERM](state, searchTerm) {
    state.searchTerm = searchTerm;
    // Any change to the filter invalidates the current page.
    state.pageInfo = { ...state.pageInfo, page: 1 };
  },

  [types.SET_SEARCH_SCOPE](state, scope) {
    state.searchScope = scope;
    state.pageInfo = { ...state.pageInfo, page: 1 };
  },

  [types.SET_FETCHED_ALL_SUITES](state, hasFetchedAllSuites) {
    state.hasFetchedAllSuites = hasFetchedAllSuites;
  },

  [types.SET_LOADING_ALL_SUITES](state, isLoadingAllSuites) {
    state.isLoadingAllSuites = isLoadingAllSuites;
  },

  [types.SET_SELECTED_SUITE_INDEX](state, selectedSuiteIndex) {
    Object.assign(state, { selectedSuiteIndex });
  },

  [types.SET_SUMMARY](state, testReports) {
    const { total } = testReports;
    state.testReports = {
      ...testReports,

      /*
        TLDR; this is a temporary mapping that will be updated once
        test suites have the new data schema

        The backend is in the middle of updating the data schema
        to have a `total` object containing the total data values.
        The test suites don't have the new schema, but the summary
        does. Currently the `test_summary.vue` component takes both
        the summary and a test suite depending on what is being viewed.
        This is a temporary change to map the new schema to the old until
        we can update the schema for the test suites also.
        Since test suites is an array, it is easier to just map the summary
        to the old schema instead of mapping every test suite to the new.
      */

      total_time: total.time,
      total_count: total.count,
      success_count: total.success,
      failed_count: total.failed,
      skipped_count: total.skipped,
      error_count: total.error,
    };
  },

  [types.TOGGLE_LOADING](state) {
    Object.assign(state, { isLoading: !state.isLoading });
  },
};
