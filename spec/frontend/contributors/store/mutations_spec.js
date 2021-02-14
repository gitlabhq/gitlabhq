import * as types from '~/contributors/stores/mutation_types';
import mutations from '~/contributors/stores/mutations';
import state from '~/contributors/stores/state';

describe('Contributors mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });

  describe('SET_LOADING_STATE', () => {
    it('should set loading flag', () => {
      const loading = true;
      mutations[types.SET_LOADING_STATE](stateCopy, loading);

      expect(stateCopy.loading).toEqual(loading);
    });
  });

  describe('SET_CHART_DATA', () => {
    const chartData = { '2017-11': 0, '2017-12': 2 };

    it('should set chart data', () => {
      mutations[types.SET_CHART_DATA](stateCopy, chartData);

      expect(stateCopy.chartData).toEqual(chartData);
    });
  });

  describe('SET_ACTIVE_BRANCH', () => {
    it('should set search query', () => {
      const branch = 'feature-branch';

      mutations[types.SET_ACTIVE_BRANCH](stateCopy, branch);

      expect(stateCopy.branch).toEqual(branch);
    });
  });
});
