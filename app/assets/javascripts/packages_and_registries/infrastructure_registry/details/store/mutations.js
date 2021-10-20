import * as types from './mutation_types';

export default {
  [types.SET_LOADING](state, isLoading) {
    state.isLoading = isLoading;
  },

  [types.SET_PACKAGE_VERSIONS](state, versions) {
    state.packageEntity = {
      ...state.packageEntity,
      versions,
    };
  },
  [types.UPDATE_PACKAGE_FILES](state, files) {
    state.packageFiles = files;
  },
};
