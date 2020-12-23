import Api from '~/api';
import { stringifyUserIds } from '../utils';
import * as types from './mutation_types';

export const fetchUserList = ({ commit, state }) => {
  commit(types.REQUEST_USER_LIST);
  return Api.fetchFeatureFlagUserList(state.projectId, state.userListIid)
    .then((response) => commit(types.RECEIVE_USER_LIST_SUCCESS, response.data))
    .catch(() => commit(types.RECEIVE_USER_LIST_ERROR));
};

export const dismissErrorAlert = ({ commit }) => commit(types.DISMISS_ERROR_ALERT);
export const addUserIds = ({ dispatch, commit }, userIds) => {
  commit(types.ADD_USER_IDS, userIds);
  return dispatch('updateUserList');
};

export const removeUserId = ({ commit, dispatch }, userId) => {
  commit(types.REMOVE_USER_ID, userId);
  return dispatch('updateUserList');
};

export const updateUserList = ({ commit, state }) => {
  commit(types.REQUEST_USER_LIST);

  return Api.updateFeatureFlagUserList(state.projectId, {
    ...state.userList,
    user_xids: stringifyUserIds(state.userIds),
  })
    .then((response) => commit(types.RECEIVE_USER_LIST_SUCCESS, response.data))
    .catch(() => commit(types.RECEIVE_USER_LIST_ERROR));
};
