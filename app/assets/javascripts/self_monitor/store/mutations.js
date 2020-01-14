import * as types from './mutation_types';

export default {
  [types.SET_ENABLED](state, enabled) {
    state.projectEnabled = enabled;
  },
  [types.SET_PROJECT_CREATED](state, created) {
    state.projectCreated = created;
  },
  [types.SET_SHOW_ALERT](state, show) {
    state.showAlert = show;
  },
  [types.SET_PROJECT_URL](state, url) {
    state.projectPath = url;
  },
  [types.SET_LOADING](state, loading) {
    state.loading = loading;
  },
  [types.SET_ALERT_CONTENT](state, content) {
    state.alertContent = content;
  },
};
