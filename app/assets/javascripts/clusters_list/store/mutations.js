import * as types from './mutation_types';

export default {
  [types.SET_LOADING_STATE](state, value) {
    state.loading = value;
  },
  [types.SET_CLUSTERS_DATA](state, clusters) {
    Object.assign(state, {
      clusters,
    });
  },
};
