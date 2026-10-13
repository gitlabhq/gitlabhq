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
          {
            author_name: 'John Smith',
            author_email: 'jawnnypoo@gmail.com',
            date: '2019-05-05',
            additions: 5,
            deletions: 1,
          },
          {
            author_name: 'John',
            author_email: 'jawnnypoo@gmail.com',
            date: '2019-05-05',
            additions: 10,
            deletions: 2,
          },
          {
            author_name: 'Carlson',
            author_email: 'carlson123@gitlab.com',
            date: '2019-03-03',
            additions: 1,
            deletions: 0,
          },
          {
            author_name: 'Carlson',
            author_email: 'carlson123@gmail.com',
            date: '2019-05-05',
            additions: 8,
            deletions: 4,
          },
          {
            author_name: 'John',
            author_email: 'jawnnypoo@gmail.com',
            date: '2019-04-04',
            additions: 3,
            deletions: 1,
          },
          {
            author_name: 'Johan',
            author_email: 'jawnnypoo@gmail.com',
            date: '2019-04-04',
            additions: 2,
            deletions: 0,
          },
          {
            author_name: 'John',
            author_email: 'JAWNNYPOO@gmail.com',
            date: '2019-03-03',
            additions: 7,
            deletions: 3,
          },
        ];
        parsed = getters.parsedData(state);
      });

      it('should group contributions by date', () => {
        expect(parsed.total).toMatchObject({ '2019-05-05': 3, '2019-03-03': 2, '2019-04-04': 2 });
        expect(parsed.additionsTotal).toMatchObject({
          '2019-05-05': 23,
          '2019-03-03': 8,
          '2019-04-04': 5,
        });
        expect(parsed.deletionsTotal).toMatchObject({
          '2019-05-05': 7,
          '2019-03-03': 3,
          '2019-04-04': 1,
        });
      });

      it('should group contributions by email and use most recent name', () => {
        expect(parsed.byAuthorEmail).toMatchObject({
          'carlson123@gmail.com': {
            name: 'Carlson',
            commits: 1,
            additions: 8,
            deletions: 4,
            dates: {
              '2019-05-05': 1,
            },
            additionsByDate: {
              '2019-05-05': 8,
            },
            deletionsByDate: {
              '2019-05-05': 4,
            },
          },
          'carlson123@gitlab.com': {
            name: 'Carlson',
            commits: 1,
            additions: 1,
            deletions: 0,
            dates: {
              '2019-03-03': 1,
            },
            additionsByDate: {
              '2019-03-03': 1,
            },
            deletionsByDate: {
              '2019-03-03': 0,
            },
          },
          'jawnnypoo@gmail.com': {
            name: 'John Smith',
            commits: 5,
            additions: 27,
            deletions: 7,
            dates: {
              '2019-03-03': 1,
              '2019-04-04': 2,
              '2019-05-05': 2,
            },
            additionsByDate: {
              '2019-03-03': 7,
              '2019-04-04': 5,
              '2019-05-05': 15,
            },
            deletionsByDate: {
              '2019-03-03': 3,
              '2019-04-04': 1,
              '2019-05-05': 3,
            },
          },
        });
      });

      it('defaults missing line change stats to zero', () => {
        const data = getters.parsedData({
          chartData: [
            {
              author_name: 'John Smith',
              author_email: 'john@example.com',
              date: '2019-05-05',
            },
          ],
        });

        expect(data.total).toMatchObject({ '2019-05-05': 1 });
        expect(data.additionsTotal).toMatchObject({ '2019-05-05': 0 });
        expect(data.deletionsTotal).toMatchObject({ '2019-05-05': 0 });
        expect(data.byAuthorEmail).toMatchObject({
          'john@example.com': {
            commits: 1,
            additions: 0,
            deletions: 0,
            additionsByDate: { '2019-05-05': 0 },
            deletionsByDate: { '2019-05-05': 0 },
          },
        });
      });
    });
  });
});
