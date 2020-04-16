import * as types from './mutation_types';

export default {
  [types.LOAD_CONTENT](state) {
    state.isLoadingContent = true;
  },
  [types.RECEIVE_CONTENT_SUCCESS](state, { title, content }) {
    state.isLoadingContent = false;
    state.isContentLoaded = true;
    state.title = title;
    state.content = content;
    state.originalContent = content;
  },
  [types.RECEIVE_CONTENT_ERROR](state) {
    state.isLoadingContent = false;
  },
  [types.SET_CONTENT](state, content) {
    state.content = content;
  },
  [types.SUBMIT_CHANGES](state) {
    state.isSavingChanges = true;
    state.submitChangesError = '';
  },
  [types.SUBMIT_CHANGES_SUCCESS](state, meta) {
    state.savedContentMeta = meta;
    state.isSavingChanges = false;
    state.originalContent = state.content;
  },
  [types.SUBMIT_CHANGES_ERROR](state, error) {
    state.submitChangesError = error;
    state.isSavingChanges = false;
  },
  [types.DISMISS_SUBMIT_CHANGES_ERROR](state) {
    state.submitChangesError = '';
  },
};
