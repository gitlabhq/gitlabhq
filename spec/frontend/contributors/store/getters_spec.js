import * as getters from '~/contributors/stores/getters';

describe('Contributors Store Getters', () => {
  const state = {};

  describe('showChart', () => {
    it('should NOT show chart if loading', () => {
      state.loading = true;

      expect(getters.showChart(state)).toEqual(false);
    });

    it('should NOT show chart there is not data', () => {
      state.loading = false;
      state.chartData = null;

      expect(getters.showChart(state)).toEqual(false);
    });

    it('should show the chart in case loading complated and there is data', () => {
      state.loading = false;
      state.chartData = true;

      expect(getters.showChart(state)).toEqual(true);
    });

    describe('parsedData', () => {
      let parsed;

      beforeAll(() => {
        state.chartData = [
          { author_name: 'John Smith', author_email: 'jawnnypoo@gmail.com', date: '2019-05-05' },
          { author_name: 'John', author_email: 'jawnnypoo@gmail.com', date: '2019-05-05' },
          { author_name: 'Carlson', author_email: 'carlson123@gitlab.com', date: '2019-03-03' },
          { author_name: 'Carlson', author_email: 'carlson123@gmail.com', date: '2019-05-05' },
          { author_name: 'John', author_email: 'jawnnypoo@gmail.com', date: '2019-04-04' },
          { author_name: 'Johan', author_email: 'jawnnypoo@gmail.com', date: '2019-04-04' },
          { author_name: 'John', author_email: 'JAWNNYPOO@gmail.com', date: '2019-03-03' },
        ];
        parsed = getters.parsedData(state);
      });

      it('should group contributions by date', () => {
        expect(parsed.total).toMatchObject({ '2019-05-05': 3, '2019-03-03': 2, '2019-04-04': 2 });
      });

      it('should group contributions by email and use most recent name', () => {
        expect(parsed.byAuthorEmail).toMatchObject({
          'carlson123@gmail.com': {
            name: 'Carlson',
            commits: 1,
            dates: {
              '2019-05-05': 1,
            },
          },
          'carlson123@gitlab.com': {
            name: 'Carlson',
            commits: 1,
            dates: {
              '2019-03-03': 1,
            },
          },
          'jawnnypoo@gmail.com': {
            name: 'John Smith',
            commits: 5,
            dates: {
              '2019-03-03': 1,
              '2019-04-04': 2,
              '2019-05-05': 2,
            },
          },
        });
      });
    });
  });
});
