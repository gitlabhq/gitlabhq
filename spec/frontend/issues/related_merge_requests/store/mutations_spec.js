import * as types from '~/issues/related_merge_requests/store/mutation_types';
import mutations from '~/issues/related_merge_requests/store/mutations';

describe('RelatedMergeRequests Store Mutations', () => {
  describe('SET_INITIAL_STATE', () => {
    it('should set initial state according to given data', () => {
      const apiEndpoint = '/api';
      const state = {};

      mutations[types.SET_INITIAL_STATE](state, { apiEndpoint });

      expect(state.apiEndpoint).toEqual(apiEndpoint);
    });
  });

  describe('REQUEST_DATA', () => {
    it('should set loading flag', () => {
      const state = {};

      mutations[types.REQUEST_DATA](state);

      expect(state.isFetchingMergeRequests).toEqual(true);
    });
  });

  describe('RECEIVE_DATA_SUCCESS', () => {
    it('should set loading flag and data', () => {
      const state = {};
      const mrs = [1, 2, 3];

      mutations[types.RECEIVE_DATA_SUCCESS](state, { data: mrs, total: mrs.length });

      expect(state.isFetchingMergeRequests).toEqual(false);
      expect(state.mergeRequests).toEqual(mrs);
      expect(state.totalCount).toEqual(mrs.length);
    });
  });

  describe('RECEIVE_DATA_ERROR', () => {
    it('should set loading and error flags', () => {
      const state = {};

      mutations[types.RECEIVE_DATA_ERROR](state);

      expect(state.isFetchingMergeRequests).toEqual(false);
      expect(state.hasErrorFetchingMergeRequests).toEqual(true);
    });
  });
});
