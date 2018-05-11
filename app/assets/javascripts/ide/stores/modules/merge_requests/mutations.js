/* eslint-disable no-param-reassign */
import * as types from './mutation_types';

export default {
  [types.REQUEST_MERGE_REQUESTS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_MERGE_REQUESTS_ERROR](state) {
    state.isLoading = false;
  },
  [types.RECEIVE_MERGE_REQUESTS_SUCCESS](state, data) {
    state.mergeRequests = data.map(mergeRequest => ({
      id: mergeRequest.iid,
      title: mergeRequest.title,
    }));
  },
};
