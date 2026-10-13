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

  describe('SET_STATS_LOADING_STATE', () => {
    it('should set stats loading flag', () => {
      const loading = true;
      mutations[types.SET_STATS_LOADING_STATE](stateCopy, loading);

      expect(stateCopy.statsLoading).toEqual(loading);
    });
  });

  describe('SET_CHART_DATA', () => {
    const chartData = { '2017-11': 0, '2017-12': 2 };

    it('should set chart data', () => {
      stateCopy.statsLoaded = true;

      mutations[types.SET_CHART_DATA](stateCopy, chartData);

      expect(stateCopy.chartData).toEqual(chartData);
      expect(stateCopy.statsLoaded).toBe(false);
    });
  });

  describe('SET_CHART_STATS', () => {
    beforeEach(() => {
      stateCopy.chartData = [
        { id: 'abc123', author_name: 'John', author_email: 'john@example.com', date: '2017-11-01' },
        { id: 'def456', author_name: 'Jane', author_email: 'jane@example.com', date: '2017-11-02' },
      ];
    });

    it('should merge chart stats by commit id', () => {
      mutations[types.SET_CHART_STATS](stateCopy, [
        { id: 'def456', additions: 10, deletions: 3 },
        { id: 'abc123', additions: 5, deletions: 1 },
      ]);

      expect(stateCopy.chartData).toEqual([
        {
          id: 'abc123',
          author_name: 'John',
          author_email: 'john@example.com',
          date: '2017-11-01',
          additions: 5,
          deletions: 1,
        },
        {
          id: 'def456',
          author_name: 'Jane',
          author_email: 'jane@example.com',
          date: '2017-11-02',
          additions: 10,
          deletions: 3,
        },
      ]);
      expect(stateCopy.statsLoaded).toBe(true);
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
