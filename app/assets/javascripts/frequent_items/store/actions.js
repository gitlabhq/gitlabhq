import Api from '~/api';
import AccessorUtilities from '~/lib/utils/accessor';
import * as types from './mutation_types';
import { getTopFrequentItems } from '../utils';

export const setNamespace = ({ commit }, namespace) => {
  commit(types.SET_NAMESPACE, namespace);
};

export const setStorageKey = ({ commit }, key) => {
  commit(types.SET_STORAGE_KEY, key);
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

  if (AccessorUtilities.isLocalStorageAccessSafe()) {
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
    membership: Boolean(gon.current_user_id),
  };

  if (state.namespace === 'projects') {
    params.order_by = 'last_activity_at';
  }

  return Api[state.namespace](searchQuery, params)
    .then(results => {
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
