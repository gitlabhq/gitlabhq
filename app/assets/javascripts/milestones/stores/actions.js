import Api from '~/api';
import * as types from './mutation_types';

export const setProjectId = ({ commit }, projectId) => commit(types.SET_PROJECT_ID, projectId);

export const setSelectedMilestones = ({ commit }, selectedMilestones) =>
  commit(types.SET_SELECTED_MILESTONES, selectedMilestones);

export const clearSelectedMilestones = ({ commit }) => commit(types.CLEAR_SELECTED_MILESTONES);

export const toggleMilestones = ({ commit, state }, selectedMilestone) => {
  const removeMilestone = state.selectedMilestones.includes(selectedMilestone);

  if (removeMilestone) {
    commit(types.REMOVE_SELECTED_MILESTONE, selectedMilestone);
  } else {
    commit(types.ADD_SELECTED_MILESTONE, selectedMilestone);
  }
};

export const search = ({ dispatch, commit }, searchQuery) => {
  commit(types.SET_SEARCH_QUERY, searchQuery);

  dispatch('searchMilestones');
};

export const fetchMilestones = ({ commit, state }) => {
  commit(types.REQUEST_START);

  Api.projectMilestones(state.projectId)
    .then(response => {
      commit(types.RECEIVE_PROJECT_MILESTONES_SUCCESS, response);
    })
    .catch(error => {
      commit(types.RECEIVE_PROJECT_MILESTONES_ERROR, error);
    })
    .finally(() => {
      commit(types.REQUEST_FINISH);
    });
};

export const searchMilestones = ({ commit, state }) => {
  commit(types.REQUEST_START);

  const options = {
    search: state.searchQuery,
    scope: 'milestones',
  };

  Api.projectSearch(state.projectId, options)
    .then(response => {
      commit(types.RECEIVE_PROJECT_MILESTONES_SUCCESS, response);
    })
    .catch(error => {
      commit(types.RECEIVE_PROJECT_MILESTONES_ERROR, error);
    })
    .finally(() => {
      commit(types.REQUEST_FINISH);
    });
};
