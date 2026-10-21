import MockAdapter from 'axios-mock-adapter';
import { createTestingPinia } from '@pinia/testing';
import { useContributors } from '~/contributors/stores';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/alert');

describe('Contributors store', () => {
  let store;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useContributors();
  });

  describe('getters', () => {
    describe('showChart', () => {
      it('should NOT show chart if loading', () => {
        store.loading = true;

        expect(store.showChart).toBe(false);
      });

      it('should NOT show chart there is not data', () => {
        store.loading = false;
        store.chartData = null;

        expect(store.showChart).toBe(false);
      });

      it('should show the chart in case loading completed and there is data', () => {
        store.loading = false;
        store.chartData = true;

        expect(store.showChart).toBe(true);
      });
    });

    describe('parsedData', () => {
      let parsed;

      beforeEach(() => {
        store.chartData = [
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
        parsed = store.parsedData;
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
        store.chartData = [
          {
            author_name: 'John Smith',
            author_email: 'john@example.com',
            date: '2019-05-05',
          },
        ];

        const data = store.parsedData;

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

    describe('parsedData without chart data', () => {
      it('returns empty totals', () => {
        store.chartData = null;

        expect(store.parsedData).toEqual({
          total: {},
          additionsTotal: {},
          deletionsTotal: {},
          byAuthorEmail: {},
        });
      });
    });
  });

  describe('actions', () => {
    describe('setLoadingState', () => {
      it('should set loading flag', () => {
        store.setLoadingState(true);

        expect(store.loading).toBe(true);
      });
    });

    describe('setStatsLoadingState', () => {
      it('should set stats loading flag', () => {
        store.setStatsLoadingState(true);

        expect(store.statsLoading).toBe(true);
      });
    });

    describe('setChartData', () => {
      const chartData = { '2017-11': 0, '2017-12': 2 };

      it('should set chart data', () => {
        store.statsLoaded = true;

        store.setChartData(chartData);

        expect(store.chartData).toEqual(chartData);
        expect(store.statsLoaded).toBe(false);
      });
    });

    describe('setChartStats', () => {
      beforeEach(() => {
        store.chartData = [
          {
            id: 'abc123',
            author_name: 'John',
            author_email: 'john@example.com',
            date: '2017-11-01',
          },
          {
            id: 'def456',
            author_name: 'Jane',
            author_email: 'jane@example.com',
            date: '2017-11-02',
          },
        ];
      });

      it('should merge chart stats by commit id', () => {
        store.setChartStats([
          { id: 'def456', additions: 10, deletions: 3 },
          { id: 'abc123', additions: 5, deletions: 1 },
        ]);

        expect(store.chartData).toEqual([
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
        expect(store.statsLoaded).toBe(true);
      });
    });

    describe('fetchChartData', () => {
      let mock;
      const endpoint = '/contributors';
      const chartData = { '2017-11': 0, '2017-12': 2 };

      beforeEach(() => {
        mock = new MockAdapter(axios);
        createAlert.mockClear();
      });

      afterEach(() => {
        mock.restore();
        jest.restoreAllMocks();
      });

      it('should set chart data with received response', async () => {
        jest.spyOn(axios, 'get');
        mock.onGet().reply(HTTP_STATUS_OK, chartData);

        const promise = store.fetchChartData(endpoint);

        expect(store.loading).toBe(true);

        const result = await promise;

        expect(result).toBe(true);
        expect(axios.get).toHaveBeenCalledWith(endpoint);
        expect(store.chartData).toEqual(chartData);
        expect(store.loading).toBe(false);
      });

      it('should show alert on API error', async () => {
        mock.onGet().reply(HTTP_STATUS_BAD_REQUEST, 'Not Found');

        const result = await store.fetchChartData(endpoint);

        expect(result).toBe(false);
        expect(store.chartData).toBeNull();
        expect(store.loading).toBe(false);
        expect(createAlert).toHaveBeenCalledWith({
          message: expect.stringMatching('error'),
        });
      });
    });

    describe('fetchChartStats', () => {
      let mock;
      const endpoint = '/contributors';
      const chartStats = [{ id: 'abc123', additions: 4, deletions: 2 }];

      beforeEach(() => {
        mock = new MockAdapter(axios);
        createAlert.mockClear();
      });

      afterEach(() => {
        mock.restore();
        jest.restoreAllMocks();
      });

      it('should set chart stats with received response', async () => {
        jest.spyOn(axios, 'get');
        mock.onGet(endpoint, { params: { with_stats: true } }).reply(HTTP_STATUS_OK, chartStats);
        store.chartData = [{ id: 'abc123' }];

        const promise = store.fetchChartStats(endpoint);

        expect(store.statsLoading).toBe(true);

        const result = await promise;

        expect(result).toBe(true);
        expect(axios.get).toHaveBeenCalledWith(endpoint, { params: { with_stats: true } });
        expect(store.chartData).toEqual([{ id: 'abc123', additions: 4, deletions: 2 }]);
        expect(store.statsLoaded).toBe(true);
        expect(store.statsLoading).toBe(false);
      });

      it.each([
        { statsLoaded: true, statsLoading: false },
        { statsLoaded: false, statsLoading: true },
      ])('should not fetch stats again with %j', async (state) => {
        jest.spyOn(axios, 'get');
        Object.assign(store, state);

        const result = await store.fetchChartStats(endpoint);

        expect(result).toBe(true);
        expect(axios.get).not.toHaveBeenCalled();
      });

      it('should show alert on API error', async () => {
        mock.onGet(endpoint, { params: { with_stats: true } }).reply(HTTP_STATUS_BAD_REQUEST);

        const result = await store.fetchChartStats(endpoint);

        expect(result).toBe(false);
        expect(store.statsLoaded).toBe(false);
        expect(store.statsLoading).toBe(false);
        expect(createAlert).toHaveBeenCalledWith({
          message: expect.stringMatching('error'),
        });
      });
    });
  });
});
