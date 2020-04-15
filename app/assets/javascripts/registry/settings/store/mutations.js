import { parseBoolean } from '~/lib/utils/common_utils';
import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_STATE](state, initialState) {
    state.projectId = initialState.projectId;
    state.formOptions = {
      cadence: JSON.parse(initialState.cadenceOptions),
      keepN: JSON.parse(initialState.keepNOptions),
      olderThan: JSON.parse(initialState.olderThanOptions),
    };
    state.enableHistoricEntries = parseBoolean(initialState.enableHistoricEntries);
    state.isAdmin = parseBoolean(initialState.isAdmin);
    state.adminSettingsPath = initialState.adminSettingsPath;
  },
  [types.UPDATE_SETTINGS](state, data) {
    state.settings = { ...state.settings, ...data.settings };
  },
  [types.SET_SETTINGS](state, settings) {
    state.settings = settings ?? state.settings;
    state.original = Object.freeze(settings);
  },
  [types.RESET_SETTINGS](state) {
    state.settings = Object.assign({}, state.original);
  },
  [types.TOGGLE_LOADING](state) {
    state.isLoading = !state.isLoading;
  },
};
