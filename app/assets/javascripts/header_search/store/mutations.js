import * as types from './mutation_types';

export default {
  [types.REQUEST_AUTOCOMPLETE](state) {
    state.loading = true;
    state.autocompleteOptions = [];
  },
  [types.RECEIVE_AUTOCOMPLETE_SUCCESS](state, data) {
    state.loading = false;
    state.autocompleteOptions = data.map((d, i) => {
      return { html_id: `autocomplete-${d.category}-${i}`, ...d };
    });
  },
  [types.RECEIVE_AUTOCOMPLETE_ERROR](state) {
    state.loading = false;
    state.autocompleteOptions = [];
  },
  [types.CLEAR_AUTOCOMPLETE](state) {
    state.autocompleteOptions = [];
  },
  [types.SET_SEARCH](state, value) {
    state.search = value;
  },
};
