import * as types from './mutation_types';

export default fetchItems => ({
  requestItems: ({ commit }) => commit(types.REQUEST_ITEMS),
  receiveItemsSuccess: ({ commit }, payload) => commit(types.RECEIVE_ITEMS_SUCCESS, payload),
  receiveItemsError: ({ commit }, payload) => commit(types.RECEIVE_ITEMS_ERROR, payload),
  fetchItems: ({ dispatch }, payload) => {
    dispatch('requestItems');

    return fetchItems(payload)
      .then(items => dispatch('receiveItemsSuccess', { items }))
      .catch(error => dispatch('receiveItemsError', { error }));
  },
});
