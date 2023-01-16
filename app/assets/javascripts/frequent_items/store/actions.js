import AccessorUtilities from '~/lib/utils/accessor';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { getGroups, getProjects } from '~/rest_api';
import { getTopFrequentItems } from '../utils';
import * as types from './mutation_types';

export const setNamespace = ({ commit }, namespace) => {
  commit(types.SET_NAMESPACE, namespace);
};

export const setStorageKey = ({ commit }, key) => {
  commit(types.SET_STORAGE_KEY, key);
};

export const toggleItemsListEditablity = ({ commit }) => {
  commit(types.TOGGLE_ITEMS_LIST_EDITABILITY);
};

export const requestFrequentItems = ({ commit }) => {
  commit(types.REQUEST_FREQUENT_ITEMS);
};
export const receiveFrequentItemsSuccess = ({ commit }, data) => {
  commit(types.RECEIVE_FREQUENT_ITEMS_SUCCESS, data);
};
export const receiveFrequentItemsError = ({ commit }) => {
  commit(types.RECEIVE_FREQUENT_ITEMS_ERROR);
};

export const fetchFrequentItems = ({ state, dispatch }) => {
  dispatch('requestFrequentItems');

  if (AccessorUtilities.canUseLocalStorage()) {
    const storedFrequentItems = JSON.parse(localStorage.getItem(state.storageKey));

    dispatch(
      'receiveFrequentItemsSuccess',
      !storedFrequentItems ? [] : getTopFrequentItems(storedFrequentItems),
    );
  } else {
    dispatch('receiveFrequentItemsError');
  }
};

export const requestSearchedItems = ({ commit }) => {
  commit(types.REQUEST_SEARCHED_ITEMS);
};
export const receiveSearchedItemsSuccess = ({ commit }, data) => {
  commit(types.RECEIVE_SEARCHED_ITEMS_SUCCESS, data);
};
export const receiveSearchedItemsError = ({ commit }) => {
  commit(types.RECEIVE_SEARCHED_ITEMS_ERROR);
};
export const fetchSearchedItems = ({ state, dispatch }, searchQuery) => {
  dispatch('requestSearchedItems');

  const params = {
    simple: true,
    per_page: 20,
    membership: isLoggedIn(),
  };

  let searchFunction;
  if (state.namespace === 'projects') {
    searchFunction = getProjects;
    params.order_by = 'last_activity_at';
  } else {
    searchFunction = getGroups;
  }

  return searchFunction(searchQuery, params)
    .then((results) => {
      dispatch('receiveSearchedItemsSuccess', results);
    })
    .catch(() => {
      dispatch('receiveSearchedItemsError');
    });
};

export const setSearchQuery = ({ commit, dispatch }, query) => {
  commit(types.SET_SEARCH_QUERY, query);

  if (query) {
    dispatch('fetchSearchedItems', query);
  } else {
    dispatch('fetchFrequentItems');
  }
};

export const removeFrequentItemSuccess = ({ commit }, itemId) => {
  commit(types.RECEIVE_REMOVE_FREQUENT_ITEM_SUCCESS, itemId);
};

export const removeFrequentItemError = ({ commit }) => {
  commit(types.RECEIVE_REMOVE_FREQUENT_ITEM_ERROR);
};

export const removeFrequentItem = ({ state, dispatch }, itemId) => {
  if (AccessorUtilities.canUseLocalStorage()) {
    try {
      const storedRawItems = JSON.parse(localStorage.getItem(state.storageKey));
      localStorage.setItem(
        state.storageKey,
        JSON.stringify(storedRawItems.filter((item) => item.id !== itemId)),
      );
      dispatch('removeFrequentItemSuccess', itemId);
    } catch {
      dispatch('removeFrequentItemError');
    }
  } else {
    dispatch('removeFrequentItemError');
  }
};
