import * as types from './mutation_types';

export default {
  [types.SET_NAMESPACE](state, namespace) {
    Object.assign(state, {
      namespace,
    });
  },
  [types.SET_STORAGE_KEY](state, storageKey) {
    Object.assign(state, {
      storageKey,
    });
  },
  [types.SET_SEARCH_QUERY](state, searchQuery) {
    const hasSearchQuery = searchQuery !== '';

    Object.assign(state, {
      searchQuery,
      isLoadingItems: true,
      hasSearchQuery,
    });
  },
  [types.REQUEST_FREQUENT_ITEMS](state) {
    Object.assign(state, {
      isLoadingItems: true,
      hasSearchQuery: false,
    });
  },
  [types.RECEIVE_FREQUENT_ITEMS_SUCCESS](state, rawItems) {
    Object.assign(state, {
      items: rawItems,
      isLoadingItems: false,
      hasSearchQuery: false,
      isFetchFailed: false,
    });
  },
  [types.RECEIVE_FREQUENT_ITEMS_ERROR](state) {
    Object.assign(state, {
      isLoadingItems: false,
      hasSearchQuery: false,
      isFetchFailed: true,
    });
  },
  [types.REQUEST_SEARCHED_ITEMS](state) {
    Object.assign(state, {
      isLoadingItems: true,
      hasSearchQuery: true,
    });
  },
  [types.RECEIVE_SEARCHED_ITEMS_SUCCESS](state, results) {
    const rawItems = results.data ? results.data : results; // Api.groups returns array, Api.projects returns object
    Object.assign(state, {
      items: rawItems.map(rawItem => ({
        id: rawItem.id,
        name: rawItem.name,
        namespace: rawItem.name_with_namespace || rawItem.full_name,
        webUrl: rawItem.web_url,
        avatarUrl: rawItem.avatar_url,
      })),
      isLoadingItems: false,
      hasSearchQuery: true,
      isFetchFailed: false,
    });
  },
  [types.RECEIVE_SEARCHED_ITEMS_ERROR](state) {
    Object.assign(state, {
      isLoadingItems: false,
      hasSearchQuery: true,
      isFetchFailed: true,
    });
  },
};
