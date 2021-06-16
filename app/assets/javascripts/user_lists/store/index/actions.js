import Api from '~/api';
import * as types from './mutation_types';

export const setUserListsOptions = ({ commit }, options) =>
  commit(types.SET_USER_LISTS_OPTIONS, options);

export const fetchUserLists = ({ state, dispatch }) => {
  dispatch('requestUserLists');

  return Api.fetchFeatureFlagUserLists(state.projectId, state.options.page)
    .then(({ data, headers }) => dispatch('receiveUserListsSuccess', { data, headers }))
    .catch(() => dispatch('receiveUserListsError'));
};

export const requestUserLists = ({ commit }) => commit(types.REQUEST_USER_LISTS);
export const receiveUserListsSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_USER_LISTS_SUCCESS, response);
export const receiveUserListsError = ({ commit }) => commit(types.RECEIVE_USER_LISTS_ERROR);

export const deleteUserList = ({ state, dispatch }, list) => {
  dispatch('requestDeleteUserList', list);

  return Api.deleteFeatureFlagUserList(state.projectId, list.iid)
    .then(() => dispatch('fetchUserLists'))
    .catch((error) =>
      dispatch('receiveDeleteUserListError', {
        list,
        error: error?.response?.data ?? error,
      }),
    );
};

export const requestDeleteUserList = ({ commit }, list) =>
  commit(types.REQUEST_DELETE_USER_LIST, list);

export const receiveDeleteUserListError = ({ commit }, { error, list }) =>
  commit(types.RECEIVE_DELETE_USER_LIST_ERROR, { error, list });
export const clearAlert = ({ commit }, index) => commit(types.RECEIVE_CLEAR_ALERT, index);
