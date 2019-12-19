import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_STATE](state, initialState) {
    state.projectId = initialState.projectId;
  },
  [types.UPDATE_SETTINGS](state, settings) {
    state.settings = { ...state.settings, ...settings };
  },
  [types.SET_SETTINGS](state, settings) {
    state.settings = settings;
    state.original = Object.freeze(settings);
  },
  [types.RESET_SETTINGS](state) {
    state.settings = { ...state.original };
  },
  [types.TOGGLE_LOADING](state) {
    state.isLoading = !state.isLoading;
  },
};
