import * as getters from '~/admin/statistics_panel/store/getters';
import createState from '~/admin/statistics_panel/store/state';

describe('Admin statistics panel getters', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('getStatistics', () => {
    describe('when statistics data exists', () => {
      it('returns an array of statistics objects with key, label and value', () => {
        state.statistics = { forks: 10, issues: 20 };

        const statisticsLabels = {
          forks: 'Forks',
          issues: 'Issues',
        };

        const statisticsData = [
          { key: 'forks', label: 'Forks', value: 10 },
          { key: 'issues', label: 'Issues', value: 20 },
        ];

        expect(getters.getStatistics(state)(statisticsLabels)).toEqual(statisticsData);
      });
    });

    describe('when no statistics data exists', () => {
      it('returns an array of statistics objects with key, label and sets value to null', () => {
        state.statistics = null;

        const statisticsLabels = {
          forks: 'Forks',
          issues: 'Issues',
        };

        const statisticsData = [
          { key: 'forks', label: 'Forks', value: null },
          { key: 'issues', label: 'Issues', value: null },
        ];

        expect(getters.getStatistics(state)(statisticsLabels)).toEqual(statisticsData);
      });
    });
  });
});
