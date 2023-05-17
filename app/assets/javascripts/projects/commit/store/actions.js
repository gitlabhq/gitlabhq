import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { PROJECT_BRANCHES_ERROR } from '../constants';
import * as types from './mutation_types';

export const clearModal = ({ commit }) => {
  commit(types.CLEAR_MODAL);
};

export const requestBranches = ({ commit }) => {
  commit(types.REQUEST_BRANCHES);
};

export const setBranchesEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_BRANCHES_ENDPOINT, endpoint);
};

export const fetchBranches = ({ commit, dispatch, state }, query) => {
  dispatch('requestBranches');

  return axios
    .get(state.branchesEndpoint, {
      params: { search: query },
    })
    .then(({ data = [] }) => {
      commit(types.RECEIVE_BRANCHES_SUCCESS, data.Branches?.length ? data.Branches : data);
    })
    .catch(() => {
      createAlert({ message: PROJECT_BRANCHES_ERROR });
    });
};

export const setBranch = ({ commit, dispatch }, branch) => {
  commit(types.SET_BRANCH, branch);
  dispatch('setSelectedBranch', branch);
};

export const setSelectedBranch = ({ commit }, branch) => {
  commit(types.SET_SELECTED_BRANCH, branch);
};

export const setSelectedProject = ({ commit, dispatch, state }, id) => {
  let { branchesEndpoint } = state;

  if (state.projects?.length) {
    branchesEndpoint = state.projects.find((p) => p.id === id).refsUrl;
  }

  commit(types.SET_SELECTED_PROJECT, id);
  dispatch('setBranchesEndpoint', branchesEndpoint);
  dispatch('fetchBranches');
};
