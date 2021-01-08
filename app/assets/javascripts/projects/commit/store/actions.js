import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { PROJECT_BRANCHES_ERROR } from '../constants';

export const clearModal = ({ commit }) => {
  commit(types.CLEAR_MODAL);
};

export const requestBranches = ({ commit }) => {
  commit(types.REQUEST_BRANCHES);
};

export const fetchBranches = ({ commit, dispatch, state }, query) => {
  dispatch('requestBranches');

  return axios
    .get(state.branchesEndpoint, {
      params: { search: query },
    })
    .then((res) => {
      commit(types.RECEIVE_BRANCHES_SUCCESS, res.data);
    })
    .catch(() => {
      createFlash({ message: PROJECT_BRANCHES_ERROR });
    });
};

export const setBranch = ({ commit, dispatch }, branch) => {
  commit(types.SET_BRANCH, branch);
  dispatch('setSelectedBranch', branch);
};

export const setSelectedBranch = ({ commit }, branch) => {
  commit(types.SET_SELECTED_BRANCH, branch);
};
