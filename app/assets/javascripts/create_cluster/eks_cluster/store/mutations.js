import * as types from './mutation_types';

export default {
  [types.SET_REGION](state, { region }) {
    state.selectedRegion = region;
  },
};
