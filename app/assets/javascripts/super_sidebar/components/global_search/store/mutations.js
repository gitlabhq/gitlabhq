import * as types from './mutation_types';

export default {
  [types.REQUEST_AUTOCOMPLETE](state) {
    state.loading = true;
    state.autocompleteOptions = [];
    state.autocompleteError = false;
  },
  [types.RECEIVE_AUTOCOMPLETE_SUCCESS](state, data) {
    state.loading = false;
    state.autocompleteOptions = [...state.autocompleteOptions].concat(data);
    state.autocompleteError = false;
  },
  [types.RECEIVE_AUTOCOMPLETE_ERROR](state) {
    state.loading = false;
    state.autocompleteOptions = [];
    state.autocompleteError = true;
  },
  [types.CLEAR_AUTOCOMPLETE](state) {
    state.autocompleteOptions = [];
    state.autocompleteError = false;
  },
  [types.SET_SEARCH](state, value) {
    state.search = value;
  },
  [types.SET_COMMAND](state, value) {
    state.commandChar = value;
  },
};
