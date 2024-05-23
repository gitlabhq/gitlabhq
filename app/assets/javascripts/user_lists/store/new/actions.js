import Api from '~/api';
import { visitUrl } from '~/lib/utils/url_utility';
import { getErrorMessages } from '../utils';
import * as types from './mutation_types';

export const dismissErrorAlert = ({ commit }) => commit(types.DISMISS_ERROR_ALERT);

export const createUserList = ({ commit, state }, userList) => {
  return Api.createFeatureFlagUserList(state.projectId, {
    ...state.userList,
    ...userList,
  })
    .then(({ data }) => visitUrl(data.path))
    .catch((response) => commit(types.RECEIVE_CREATE_USER_LIST_ERROR, getErrorMessages(response)));
};
