import * as types from './mutation_types';

export default {
  [types.SET_SELECTED_FILTERS](state, params) {
    const {
      selectedSourceBranch = null,
      selectedSourceBranchList = [],
      selectedTargetBranch = null,
      selectedTargetBranchList = [],
      selectedAuthor = null,
      selectedAuthorList = [],
      selectedMilestone = null,
      selectedMilestoneList = [],
      selectedAssignee = null,
      selectedAssigneeList = [],
      selectedLabel = null,
      selectedLabelList = [],
    } = params;
    state.branches.source.selected = selectedSourceBranch;
    state.branches.source.selectedList = selectedSourceBranchList;
    state.branches.target.selected = selectedTargetBranch;
    state.branches.target.selectedList = selectedTargetBranchList;
    state.authors.selected = selectedAuthor;
    state.authors.selectedList = selectedAuthorList;
    state.assignees.selected = selectedAssignee;
    state.assignees.selectedList = selectedAssigneeList;
    state.milestones.selected = selectedMilestone;
    state.milestones.selectedList = selectedMilestoneList;
    state.labels.selected = selectedLabel;
    state.labels.selectedList = selectedLabelList;
  },
  [types.SET_MILESTONES_ENDPOINT](state, milestonesEndpoint) {
    state.milestonesEndpoint = milestonesEndpoint;
  },
  [types.SET_LABELS_ENDPOINT](state, labelsEndpoint) {
    state.labelsEndpoint = labelsEndpoint;
  },
  [types.SET_GROUP_ENDPOINT](state, groupEndpoint) {
    state.groupEndpoint = groupEndpoint;
  },
  [types.SET_PROJECT_ENDPOINT](state, projectEndpoint) {
    state.projectEndpoint = projectEndpoint;
  },
  [types.REQUEST_MILESTONES](state) {
    state.milestones.isLoading = true;
  },
  [types.RECEIVE_MILESTONES_SUCCESS](state, data) {
    state.milestones.isLoading = false;
    state.milestones.data = data;
    state.milestones.errorCode = null;
  },
  [types.RECEIVE_MILESTONES_ERROR](state, errorCode) {
    state.milestones.isLoading = false;
    state.milestones.errorCode = errorCode;
    state.milestones.data = [];
  },
  [types.REQUEST_LABELS](state) {
    state.labels.isLoading = true;
  },
  [types.RECEIVE_LABELS_SUCCESS](state, data) {
    state.labels.isLoading = false;
    state.labels.data = data;
    state.labels.errorCode = null;
  },
  [types.RECEIVE_LABELS_ERROR](state, errorCode) {
    state.labels.isLoading = false;
    state.labels.errorCode = errorCode;
    state.labels.data = [];
  },
  [types.REQUEST_AUTHORS](state) {
    state.authors.isLoading = true;
  },
  [types.RECEIVE_AUTHORS_SUCCESS](state, data) {
    state.authors.isLoading = false;
    state.authors.data = data;
    state.authors.errorCode = null;
  },
  [types.RECEIVE_AUTHORS_ERROR](state, errorCode) {
    state.authors.isLoading = false;
    state.authors.errorCode = errorCode;
    state.authors.data = [];
  },
  [types.REQUEST_ASSIGNEES](state) {
    state.assignees.isLoading = true;
  },
  [types.RECEIVE_ASSIGNEES_SUCCESS](state, data) {
    state.assignees.isLoading = false;
    state.assignees.data = data;
    state.assignees.errorCode = null;
  },
  [types.RECEIVE_ASSIGNEES_ERROR](state, errorCode) {
    state.assignees.isLoading = false;
    state.assignees.errorCode = errorCode;
    state.assignees.data = [];
  },
  [types.REQUEST_BRANCHES](state) {
    state.branches.isLoading = true;
  },
  [types.RECEIVE_BRANCHES_SUCCESS](state, data) {
    state.branches.isLoading = false;
    state.branches.data = data;
    state.branches.errorCode = null;
  },
  [types.RECEIVE_BRANCHES_ERROR](state, errorCode) {
    state.branches.isLoading = false;
    state.branches.errorCode = errorCode;
    state.branches.data = [];
  },
};
