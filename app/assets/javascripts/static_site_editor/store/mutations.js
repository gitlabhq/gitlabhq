import * as types from './mutation_types';

export default {
  [types.LOAD_CONTENT](state) {
    state.isLoadingContent = true;
  },
  [types.RECEIVE_CONTENT_SUCCESS](state, { title, content }) {
    state.isLoadingContent = false;
    state.title = title;
    state.content = content;
  },
  [types.RECEIVE_CONTENT_ERROR](state) {
    state.isLoadingContent = false;
  },
};
