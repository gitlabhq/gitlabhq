import * as types from '~/admin/statistics_panel/store/mutation_types';
import mutations from '~/admin/statistics_panel/store/mutations';
import getInitialState from '~/admin/statistics_panel/store/state';
import mockStatistics from '../mock_data';

describe('Admin statistics panel mutations', () => {
  let state;

  beforeEach(() => {
    state = getInitialState();
  });

  describe(`${types.REQUEST_STATISTICS}`, () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_STATISTICS](state);

      expect(state.isLoading).toBe(true);
    });
  });

  describe(`${types.RECEIVE_STATISTICS_SUCCESS}`, () => {
    it('updates the store with the with statistics', () => {
      mutations[types.RECEIVE_STATISTICS_SUCCESS](state, mockStatistics);

      expect(state.isLoading).toBe(false);
      expect(state.error).toBe(null);
      expect(state.statistics).toEqual(mockStatistics);
    });
  });

  describe(`${types.RECEIVE_STATISTICS_ERROR}`, () => {
    it('sets error and clears data', () => {
      const error = 500;
      mutations[types.RECEIVE_STATISTICS_ERROR](state, error);

      expect(state.isLoading).toBe(false);
      expect(state.error).toBe(error);
      expect(state.statistics).toEqual(null);
    });
  });
});
