import * as types from './mutation_types';

export default {
  [types.SET_PATHS](state, paths) {
    state.basePath = paths.basePath;
    state.headPath = paths.headPath;
    state.baseBlobPath = paths.baseBlobPath;
    state.headBlobPath = paths.headBlobPath;
    state.helpPath = paths.helpPath;
  },
  [types.REQUEST_REPORTS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_REPORTS_SUCCESS](state, data) {
    state.hasError = false;
    state.isLoading = false;
    state.newIssues = data.newIssues;
    state.resolvedIssues = data.resolvedIssues;
  },
  [types.RECEIVE_REPORTS_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },
};
