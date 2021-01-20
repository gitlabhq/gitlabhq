import Api from '~/api';
import * as types from './mutation_types';

export const setProjectId = ({ commit }, projectId) => commit(types.SET_PROJECT_ID, projectId);
export const setGroupId = ({ commit }, groupId) => commit(types.SET_GROUP_ID, groupId);
export const setGroupMilestonesAvailable = ({ commit }, groupMilestonesAvailable) =>
  commit(types.SET_GROUP_MILESTONES_AVAILABLE, groupMilestonesAvailable);

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

export const search = ({ dispatch, commit, getters }, searchQuery) => {
  commit(types.SET_SEARCH_QUERY, searchQuery);

  dispatch('searchProjectMilestones');
  if (getters.groupMilestonesEnabled) {
    dispatch('searchGroupMilestones');
  }
};

export const fetchMilestones = ({ dispatch, getters }) => {
  dispatch('fetchProjectMilestones');
  if (getters.groupMilestonesEnabled) {
    dispatch('fetchGroupMilestones');
  }
};

export const fetchProjectMilestones = ({ commit, state }) => {
  commit(types.REQUEST_START);

  Api.projectMilestones(state.projectId)
    .then((response) => {
      commit(types.RECEIVE_PROJECT_MILESTONES_SUCCESS, response);
    })
    .catch((error) => {
      commit(types.RECEIVE_PROJECT_MILESTONES_ERROR, error);
    })
    .finally(() => {
      commit(types.REQUEST_FINISH);
    });
};

export const fetchGroupMilestones = ({ commit, state }) => {
  commit(types.REQUEST_START);

  Api.groupMilestones(state.groupId)
    .then((response) => {
      commit(types.RECEIVE_GROUP_MILESTONES_SUCCESS, response);
    })
    .catch((error) => {
      commit(types.RECEIVE_GROUP_MILESTONES_ERROR, error);
    })
    .finally(() => {
      commit(types.REQUEST_FINISH);
    });
};

export const searchProjectMilestones = ({ commit, state }) => {
  const options = {
    search: state.searchQuery,
    scope: 'milestones',
  };

  commit(types.REQUEST_START);

  Api.projectSearch(state.projectId, options)
    .then((response) => {
      commit(types.RECEIVE_PROJECT_MILESTONES_SUCCESS, response);
    })
    .catch((error) => {
      commit(types.RECEIVE_PROJECT_MILESTONES_ERROR, error);
    })
    .finally(() => {
      commit(types.REQUEST_FINISH);
    });
};

export const searchGroupMilestones = ({ commit, state }) => {
  const options = {
    search: state.searchQuery,
  };

  commit(types.REQUEST_START);

  Api.groupMilestones(state.groupId, options)
    .then((response) => {
      commit(types.RECEIVE_GROUP_MILESTONES_SUCCESS, response);
    })
    .catch((error) => {
      commit(types.RECEIVE_GROUP_MILESTONES_ERROR, error);
    })
    .finally(() => {
      commit(types.REQUEST_FINISH);
    });
};
