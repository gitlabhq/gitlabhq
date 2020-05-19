import * as types from './mutation_types';

export default {
  [types.SET_LOADING_STATE](state, value) {
    state.loading = value;
  },
  [types.SET_CLUSTERS_DATA](state, { data, paginationInformation }) {
    Object.assign(state, {
      clusters: data.clusters,
      clustersPerPage: paginationInformation.perPage,
      hasAncestorClusters: data.has_ancestor_clusters,
      totalCulsters: paginationInformation.total,
    });
  },
  [types.SET_PAGE](state, value) {
    state.page = Number(value) || 1;
  },
};
