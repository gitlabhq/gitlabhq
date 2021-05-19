import * as types from './mutation_types';

export default {
  /**
   * Sets isLoading to true while the request is being made.
   * @param {Object} state
   */
  [types.REQUEST_RELEASES](state) {
    state.isLoading = true;
  },

  /**
   * Sets isLoading to false.
   * Sets hasError to false.
   * Sets the received data
   * Sets the received pagination information
   * @param {Object} state
   * @param {Object} resp
   */
  [types.RECEIVE_RELEASES_SUCCESS](state, { data, pageInfo }) {
    state.hasError = false;
    state.isLoading = false;
    state.releases = data;
    state.pageInfo = pageInfo;
  },

  /**
   * Sets isLoading to false.
   * Sets hasError to true.
   * Resets the data
   * @param {Object} state
   * @param {Object} data
   */
  [types.RECEIVE_RELEASES_ERROR](state) {
    state.isLoading = false;
    state.releases = [];
    state.hasError = true;
    state.pageInfo = {};
  },

  [types.SET_SORTING](state, sorting) {
    state.sorting = { ...state.sorting, ...sorting };
  },
};
