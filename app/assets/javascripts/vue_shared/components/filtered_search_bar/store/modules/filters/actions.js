import Api from '~/api';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import * as types from './mutation_types';

export const setEndpoints = ({ commit }, params) => {
  const { milestonesEndpoint, labelsEndpoint, groupEndpoint, projectEndpoint } = params;
  commit(types.SET_MILESTONES_ENDPOINT, milestonesEndpoint);
  commit(types.SET_LABELS_ENDPOINT, labelsEndpoint);
  commit(types.SET_GROUP_ENDPOINT, groupEndpoint);
  commit(types.SET_PROJECT_ENDPOINT, projectEndpoint);
};

export function fetchBranches({ commit, state }, search = '') {
  const { projectEndpoint } = state;
  commit(types.REQUEST_BRANCHES);

  return Api.branches(projectEndpoint, search)
    .then((response) => {
      commit(types.RECEIVE_BRANCHES_SUCCESS, response.data);
      return response;
    })
    .catch(({ response }) => {
      const { status } = response;
      commit(types.RECEIVE_BRANCHES_ERROR, status);
      createFlash({
        message: __('Failed to load branches. Please try again.'),
      });
    });
}

export const fetchMilestones = ({ commit, state }, search_title = '') => {
  commit(types.REQUEST_MILESTONES);
  const { milestonesEndpoint } = state;

  return axios
    .get(milestonesEndpoint, { params: { search_title } })
    .then((response) => {
      commit(types.RECEIVE_MILESTONES_SUCCESS, response.data);
      return response;
    })
    .catch(({ response }) => {
      const { status } = response;
      commit(types.RECEIVE_MILESTONES_ERROR, status);
      createFlash({
        message: __('Failed to load milestones. Please try again.'),
      });
    });
};

export const fetchLabels = ({ commit, state }, search = '') => {
  commit(types.REQUEST_LABELS);

  return axios
    .get(state.labelsEndpoint, { params: { search } })
    .then((response) => {
      commit(types.RECEIVE_LABELS_SUCCESS, response.data);
      return response;
    })
    .catch(({ response }) => {
      const { status } = response;
      commit(types.RECEIVE_LABELS_ERROR, status);
      createFlash({
        message: __('Failed to load labels. Please try again.'),
      });
    });
};

function fetchUser(options = {}) {
  const { commit, projectEndpoint, groupEndpoint, query, action, errorMessage } = options;
  commit(`REQUEST_${action}`);

  let fetchUserPromise;
  if (projectEndpoint) {
    fetchUserPromise = Api.projectUsers(projectEndpoint, query).then((data) => ({ data }));
  } else {
    fetchUserPromise = Api.groupMembers(groupEndpoint, { query });
  }

  return fetchUserPromise
    .then((response) => {
      commit(`RECEIVE_${action}_SUCCESS`, response.data);
      return response;
    })
    .catch(({ response }) => {
      const { status } = response;
      commit(`RECEIVE_${action}_ERROR`, status);
      createFlash({
        message: errorMessage,
      });
    });
}

export const fetchAuthors = ({ commit, state }, query = '') => {
  const { projectEndpoint, groupEndpoint } = state;

  return fetchUser({
    commit,
    query,
    projectEndpoint,
    groupEndpoint,
    action: 'AUTHORS',
    errorMessage: __('Failed to load authors. Please try again.'),
  });
};

export const fetchAssignees = ({ commit, state }, query = '') => {
  const { projectEndpoint, groupEndpoint } = state;

  return fetchUser({
    commit,
    query,
    projectEndpoint,
    groupEndpoint,
    action: 'ASSIGNEES',
    errorMessage: __('Failed to load assignees. Please try again.'),
  });
};

export const setFilters = ({ commit, dispatch }, filters) => {
  commit(types.SET_SELECTED_FILTERS, filters);

  return dispatch('setFilters', filters, { root: true });
};

export const initialize = ({ commit }, initialFilters) => {
  commit(types.SET_SELECTED_FILTERS, initialFilters);
};
