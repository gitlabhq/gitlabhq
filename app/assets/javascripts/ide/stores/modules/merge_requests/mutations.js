import * as types from './mutation_types';

export default {
  [types.REQUEST_MERGE_REQUESTS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_MERGE_REQUESTS_ERROR](state) {
    state.isLoading = false;
  },
  [types.RECEIVE_MERGE_REQUESTS_SUCCESS](state, data) {
    state.isLoading = false;
    state.mergeRequests = data.map((mergeRequest) => ({
      id: mergeRequest.id,
      iid: mergeRequest.iid,
      title: mergeRequest.title,
      projectId: mergeRequest.project_id,
      projectPathWithNamespace: mergeRequest.references.full.replace(
        mergeRequest.references.short,
        '',
      ),
    }));
  },
  [types.RESET_MERGE_REQUESTS](state) {
    state.mergeRequests = [];
  },
};
