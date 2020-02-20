import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_STATE](state, initialState) {
    state.projectId = initialState.projectId;
    state.formOptions = {
      cadence: JSON.parse(initialState.cadenceOptions),
      keepN: JSON.parse(initialState.keepNOptions),
      olderThan: JSON.parse(initialState.olderThanOptions),
    };
  },
  [types.UPDATE_SETTINGS](state, data) {
    state.settings = { ...state.settings, ...data.settings };
  },
  [types.SET_SETTINGS](state, settings) {
    state.settings = settings;
    state.original = Object.freeze(settings);
  },
  [types.SET_IS_DISABLED](state, isDisabled) {
    state.isDisabled = isDisabled;
  },
  [types.RESET_SETTINGS](state) {
    state.settings = { ...state.original };
  },
  [types.TOGGLE_LOADING](state) {
    state.isLoading = !state.isLoading;
  },
};
