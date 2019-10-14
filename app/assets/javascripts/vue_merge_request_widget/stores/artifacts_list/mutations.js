import * as types from './mutation_types';

export default {
  [types.SET_ENDPOINT](state, endpoint) {
    state.endpoint = endpoint;
  },
  [types.REQUEST_ARTIFACTS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_ARTIFACTS_SUCCESS](state, response) {
    state.hasError = false;
    state.isLoading = false;

    state.artifacts = response;
  },
  [types.RECEIVE_ARTIFACTS_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;

    state.artifacts = [];
  },
};
