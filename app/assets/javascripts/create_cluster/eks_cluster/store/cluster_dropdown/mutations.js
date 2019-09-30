import * as types from './mutation_types';

export default {
  [types.REQUEST_ITEMS](state) {
    state.isLoadingItems = true;
    state.loadingItemsError = null;
  },
  [types.RECEIVE_ITEMS_SUCCESS](state, { items }) {
    state.isLoadingItems = false;
    state.items = items;
  },
  [types.RECEIVE_ITEMS_ERROR](state, { error }) {
    state.isLoadingItems = false;
    state.loadingItemsError = error;
  },
};
