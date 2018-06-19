/* eslint-disable no-param-reassign */
import * as types from './mutation_types';

export default {
  [types.REQUEST_MERGE_REQUESTS](state, type) {
    state[type].isLoading = true;
  },
  [types.RECEIVE_MERGE_REQUESTS_ERROR](state, type) {
    state[type].isLoading = false;
  },
  [types.RECEIVE_MERGE_REQUESTS_SUCCESS](state, { type, data }) {
    state[type].isLoading = false;
    state[type].mergeRequests = data.map(mergeRequest => ({
      id: mergeRequest.id,
      iid: mergeRequest.iid,
      title: mergeRequest.title,
      projectId: mergeRequest.project_id,
      projectPathWithNamespace: mergeRequest.web_url
        .replace(`${gon.gitlab_url}/`, '')
        .replace(`/merge_requests/${mergeRequest.iid}`, ''),
    }));
  },
  [types.RESET_MERGE_REQUESTS](state, type) {
    state[type].mergeRequests = [];
  },
};
