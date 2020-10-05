import * as types from './mutation_types';

export default {
  [types.SET_ENDPOINT](state, endpoint) {
    state.endpoint = endpoint;
  },
  [types.SET_PATH](state, path) {
    state.path = path;
  },
  [types.REQUEST_CREATE_FEATURE_FLAG](state) {
    state.isSendingRequest = true;
    state.error = [];
  },
  [types.RECEIVE_CREATE_FEATURE_FLAG_SUCCESS](state) {
    state.isSendingRequest = false;
  },
  [types.RECEIVE_CREATE_FEATURE_FLAG_ERROR](state, error) {
    state.isSendingRequest = false;
    state.error = error.message || [];
  },
};
