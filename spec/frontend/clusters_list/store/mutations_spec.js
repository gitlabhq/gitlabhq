import * as types from '~/clusters_list/store/mutation_types';
import mutations from '~/clusters_list/store/mutations';
import getInitialState from '~/clusters_list/store/state';
import { apiData } from '../mock_data';

describe('Admin statistics panel mutations', () => {
  let state;

  const paginationInformation = {
    nextPage: 1,
    page: 1,
    perPage: 20,
    previousPage: 1,
    total: apiData.clusters.length,
    totalPages: 1,
  };

  beforeEach(() => {
    state = getInitialState();
  });

  describe(`${types.SET_CLUSTERS_DATA}`, () => {
    it('sets clusters and pagination values', () => {
      mutations[types.SET_CLUSTERS_DATA](state, { data: apiData, paginationInformation });

      expect(state.clusters).toBe(apiData.clusters);
      expect(state.clustersPerPage).toBe(paginationInformation.perPage);
      expect(state.hasAncestorClusters).toBe(apiData.has_ancestor_clusters);
      expect(state.totalClusters).toBe(paginationInformation.total);
    });
  });

  describe(`${types.SET_LOADING_CLUSTERS}`, () => {
    it('sets value to false', () => {
      expect(state.loadingClusters).toBe(true);

      mutations[types.SET_LOADING_CLUSTERS](state, false);

      expect(state.loadingClusters).toBe(false);
    });
  });

  describe(`${types.SET_LOADING_NODES}`, () => {
    it('sets value to false', () => {
      expect(state.loadingNodes).toBe(true);

      mutations[types.SET_LOADING_NODES](state, false);

      expect(state.loadingNodes).toBe(false);
    });
  });

  describe(`${types.SET_PAGE}`, () => {
    it('changes page value', () => {
      mutations[types.SET_PAGE](state, 123);

      expect(state.page).toBe(123);
    });
  });

  describe(`${types.SET_CLUSTERS_PER_PAGE}`, () => {
    it('changes clustersPerPage value', () => {
      mutations[types.SET_CLUSTERS_PER_PAGE](state, 123);

      expect(state.clustersPerPage).toBe(123);
    });
  });
});
