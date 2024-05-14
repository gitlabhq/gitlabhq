import * as types from './mutation_types';

export default {
  [types.SET_PROJECT_ID](state, projectId) {
    state.projectId = projectId;
  },
  [types.SET_GROUP_ID](state, groupId) {
    state.groupId = groupId;
  },
  [types.SET_GROUP_MILESTONES_AVAILABLE](state, groupMilestonesAvailable) {
    state.groupMilestonesAvailable = groupMilestonesAvailable;
  },
  [types.SET_SELECTED_MILESTONES](state, selectedMilestones) {
    state.selectedMilestones = selectedMilestones;
  },
  [types.CLEAR_SELECTED_MILESTONES](state) {
    state.selectedMilestones = [];
  },
  [types.ADD_SELECTED_MILESTONE](state, selectedMilestone) {
    state.selectedMilestones.push(selectedMilestone);
  },
  [types.REMOVE_SELECTED_MILESTONE](state, selectedMilestone) {
    state.selectedMilestones = state.selectedMilestones.filter(
      (milestone) => milestone !== selectedMilestone,
    );
  },
  [types.SET_SEARCH_QUERY](state, searchQuery) {
    state.searchQuery = searchQuery;
  },
  [types.REQUEST_START](state) {
    state.requestCount += 1;
  },
  [types.REQUEST_FINISH](state) {
    state.requestCount -= 1;
  },
  [types.RECEIVE_PROJECT_MILESTONES_SUCCESS](state, response) {
    state.matches.projectMilestones = {
      list: response.data.map(({ title }) => ({ text: title, value: title })),
      totalCount: parseInt(response.headers['x-total'], 10) || response.data.length,
      error: null,
    };
  },
  [types.RECEIVE_PROJECT_MILESTONES_ERROR](state, error) {
    state.matches.projectMilestones = {
      list: [],
      totalCount: 0,
      error,
    };
  },
  [types.RECEIVE_GROUP_MILESTONES_SUCCESS](state, response) {
    state.matches.groupMilestones = {
      list: response.data.map(({ title }) => ({ text: title, value: title })),
      totalCount: parseInt(response.headers['x-total'], 10) || response.data.length,
      error: null,
    };
  },
  [types.RECEIVE_GROUP_MILESTONES_ERROR](state, error) {
    state.matches.groupMilestones = {
      list: [],
      totalCount: 0,
      error,
    };
  },
};
