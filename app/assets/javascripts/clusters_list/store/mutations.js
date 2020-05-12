import * as types from './mutation_types';

export default {
  [types.SET_LOADING_STATE](state, value) {
    state.loading = value;
  },
  [types.SET_CLUSTERS_DATA](state, data) {
    Object.assign(state, {
      clusters: data.clusters,
      hasAncestorClusters: data.has_ancestor_clusters,
    });
  },
};
