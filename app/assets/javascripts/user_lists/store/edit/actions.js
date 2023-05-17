import Api from '~/api';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { getErrorMessages } from '../utils';
import * as types from './mutation_types';

export const fetchUserList = ({ commit, state }) => {
  commit(types.REQUEST_USER_LIST);
  return Api.fetchFeatureFlagUserList(state.projectId, state.userListIid)
    .then(({ data }) => commit(types.RECEIVE_USER_LIST_SUCCESS, data))
    .catch((response) => commit(types.RECEIVE_USER_LIST_ERROR, getErrorMessages(response)));
};

export const dismissErrorAlert = ({ commit }) => commit(types.DISMISS_ERROR_ALERT);

export const updateUserList = ({ commit, state }, userList) => {
  return Api.updateFeatureFlagUserList(state.projectId, {
    iid: userList.iid,
    name: userList.name,
  })
    .then(({ data }) => redirectTo(data.path)) // eslint-disable-line import/no-deprecated
    .catch((response) => commit(types.RECEIVE_USER_LIST_ERROR, getErrorMessages(response)));
};
