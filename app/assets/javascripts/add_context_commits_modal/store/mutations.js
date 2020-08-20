import * as types from './mutation_types';

export default {
  [types.SET_BASE_CONFIG](state, options) {
    Object.assign(state, { ...options });
  },
  [types.SET_TABINDEX](state, tabIndex) {
    state.tabIndex = tabIndex;
  },
  [types.FETCH_COMMITS](state) {
    state.isLoadingCommits = true;
    state.commitsLoadingError = false;
  },
  [types.SET_COMMITS](state, commits) {
    state.commits = commits;
    state.isLoadingCommits = false;
    state.commitsLoadingError = false;
  },
  [types.SET_COMMITS_SILENT](state, commits) {
    state.commits = commits;
  },
  [types.FETCH_COMMITS_ERROR](state) {
    state.commitsLoadingError = true;
    state.isLoadingCommits = false;
  },
  [types.FETCH_CONTEXT_COMMITS](state) {
    state.isLoadingContextCommits = true;
    state.contextCommitsLoadingError = false;
  },
  [types.SET_CONTEXT_COMMITS](state, contextCommits) {
    state.contextCommits = contextCommits;
    state.isLoadingContextCommits = false;
    state.contextCommitsLoadingError = false;
  },
  [types.FETCH_CONTEXT_COMMITS_ERROR](state) {
    state.contextCommitsLoadingError = true;
    state.isLoadingContextCommits = false;
  },
  [types.SET_SELECTED_COMMITS](state, commits) {
    state.selectedCommits = commits;
  },
  [types.SET_SEARCH_TEXT](state, searchText) {
    state.searchText = searchText;
  },
  [types.SET_TO_REMOVE_COMMITS](state, commits) {
    state.toRemoveCommits = commits;
  },
  [types.RESET_MODAL_STATE](state) {
    state.tabIndex = 0;
    state.commits = [];
    state.contextCommits = [];
    state.selectedCommits = [];
    state.toRemoveCommits = [];
    state.searchText = '';
  },
};
