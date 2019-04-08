import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_STATE](state, { apiEndpoint }) {
    state.apiEndpoint = apiEndpoint;
  },
  [types.REQUEST_DATA](state) {
    state.isFetchingMergeRequests = true;
  },
  [types.RECEIVE_DATA_SUCCESS](state, { data, total }) {
    state.isFetchingMergeRequests = false;
    state.mergeRequests = data;
    state.totalCount = total;
  },
  [types.RECEIVE_DATA_ERROR](state) {
    state.isFetchingMergeRequests = false;
    state.hasErrorFetchingMergeRequests = true;
  },
};
