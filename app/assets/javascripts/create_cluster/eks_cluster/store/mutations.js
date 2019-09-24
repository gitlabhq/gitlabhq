import * as types from './mutation_types';

export default {
  [types.REQUEST_REGIONS](state) {
    state.isLoadingRegions = true;
    state.loadingRegionsError = null;
  },
  [types.RECEIVE_REGIONS_SUCCESS](state, { regions }) {
    state.isLoadingRegions = false;
    state.regions = regions;
  },
  [types.RECEIVE_REGIONS_ERROR](state, { error }) {
    state.isLoadingRegions = false;
    state.loadingRegionsError = error;
  },
  [types.SET_REGION](state, { region }) {
    state.selectedRegion = region;
  },
};
