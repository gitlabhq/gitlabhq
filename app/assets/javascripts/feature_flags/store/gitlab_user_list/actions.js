import Api from '~/api';
import * as types from './mutation_types';

const getErrorMessages = (error) => [].concat(error?.response?.data?.message ?? error.message);

export const fetchUserLists = ({ commit, state: { filter, projectId } }) => {
  commit(types.FETCH_USER_LISTS);

  return Api.searchFeatureFlagUserLists(projectId, filter)
    .then(({ data }) => commit(types.RECEIVE_USER_LISTS_SUCCESS, data))
    .catch((error) => commit(types.RECEIVE_USER_LISTS_ERROR, getErrorMessages(error)));
};

export const setFilter = ({ commit, dispatch }, filter) => {
  commit(types.SET_FILTER, filter);
  return dispatch('fetchUserLists');
};
