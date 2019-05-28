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
   * @param {Object} state
   * @param {Object} data
   */
  [types.RECEIVE_RELEASES_SUCCESS](state, data) {
    state.hasError = false;
    state.isLoading = false;
    state.releases = data;
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
  },
};
