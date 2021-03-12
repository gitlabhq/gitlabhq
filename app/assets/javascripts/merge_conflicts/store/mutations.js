import { VIEW_TYPES } from '../constants';
import * as types from './mutation_types';

export default {
  [types.SET_LOADING_STATE]: (state, value) => {
    state.isLoading = value;
  },
  [types.SET_ERROR_STATE]: (state, value) => {
    state.hasError = value;
  },
  [types.SET_FAILED_REQUEST]: (state, value) => {
    state.hasError = true;
    state.conflictsData.errorMessage = value;
  },
  [types.SET_VIEW_TYPE]: (state, value) => {
    state.diffView = value;
    state.isParallel = value === VIEW_TYPES.PARALLEL;
  },
  [types.SET_SUBMIT_STATE]: (state, value) => {
    state.isSubmitting = value;
  },
  [types.SET_CONFLICTS_DATA]: (state, data) => {
    state.conflictsData = {
      files: data.files,
      commitMessage: data.commit_message,
      sourceBranch: data.source_branch,
      targetBranch: data.target_branch,
      shortCommitSha: data.commit_sha.slice(0, 7),
    };
  },
  [types.UPDATE_CONFLICTS_DATA]: (state, payload) => {
    state.conflictsData = {
      ...state.conflictsData,
      ...payload,
    };
  },
  [types.UPDATE_FILE]: (state, { file, index }) => {
    state.conflictsData.files.splice(index, 1, file);
  },
};
