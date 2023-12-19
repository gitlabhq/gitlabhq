import * as types from './mutation_types';

export default {
  [types.REQUEST_GROUPS](state) {
    state.fetchingGroups = true;
  },
  [types.RECEIVE_GROUPS_SUCCESS](state, data) {
    state.fetchingGroups = false;
    state.groups = [...data];
  },
  [types.RECEIVE_GROUPS_ERROR](state) {
    state.fetchingGroups = false;
    state.groups = [];
  },
  [types.REQUEST_PROJECTS](state) {
    state.fetchingProjects = true;
  },
  [types.RECEIVE_PROJECTS_SUCCESS](state, data) {
    state.fetchingProjects = false;
    state.projects = [...data];
  },
  [types.RECEIVE_PROJECTS_ERROR](state) {
    state.fetchingProjects = false;
    state.projects = [];
  },
  [types.SET_QUERY](state, { key, value }) {
    state.query = { ...state.query, [key]: value };
  },
  [types.SET_SIDEBAR_DIRTY](state, value) {
    state.sidebarDirty = value;
  },
  [types.LOAD_FREQUENT_ITEMS](state, { key, data }) {
    state.frequentItems[key] = data;
  },
  [types.RECEIVE_NAVIGATION_COUNT](state, { key, count }) {
    const item = { ...state.navigation[key], count, count_link: null };
    state.navigation = { ...state.navigation, [key]: item };
  },
  [types.REQUEST_AGGREGATIONS](state) {
    state.aggregations = { fetching: true, error: false, data: [] };
  },
  [types.RECEIVE_AGGREGATIONS_SUCCESS](state, data) {
    state.aggregations = { fetching: false, error: false, data: [...data] };
  },
  [types.RECEIVE_AGGREGATIONS_ERROR](state) {
    state.aggregations = { fetching: false, error: true, data: [] };
  },
  [types.SET_LABEL_SEARCH_STRING](state, value) {
    state.searchLabelString = value;
  },
};
