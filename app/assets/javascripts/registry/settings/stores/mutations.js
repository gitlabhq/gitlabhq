import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_STATE](state, initialState) {
    state.helpPagePath = initialState.helpPagePath;
    state.registrySettingsEndpoint = initialState.registrySettingsEndpoint;
  },
};
