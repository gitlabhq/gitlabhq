import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/contributors/stores/actions';
import * as types from '~/contributors/stores/mutation_types';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/alert');

describe('Contributors store actions', () => {
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

    it('should commit SET_CHART_DATA with received response', () => {
      jest.spyOn(axios, 'get');
      mock.onGet().reply(HTTP_STATUS_OK, chartData);

      return testAction(
        actions.fetchChartData,
        endpoint,
        {},
        [
          { type: types.SET_LOADING_STATE, payload: true },
          { type: types.SET_CHART_DATA, payload: chartData },
          { type: types.SET_LOADING_STATE, payload: false },
        ],
        [],
      ).then((result) => {
        expect(result).toBe(true);
        expect(axios.get).toHaveBeenCalledWith(endpoint);
      });
    });

    it('should show alert on API error', async () => {
      mock.onGet().reply(HTTP_STATUS_BAD_REQUEST, 'Not Found');

      const result = await testAction(
        actions.fetchChartData,
        endpoint,
        {},
        [
          { type: types.SET_LOADING_STATE, payload: true },
          { type: types.SET_LOADING_STATE, payload: false },
        ],
        [],
      );

      expect(result).toBe(false);
      expect(createAlert).toHaveBeenCalledWith({
        message: expect.stringMatching('error'),
      });
    });
  });

  describe('fetchChartStats', () => {
    let mock;
    const endpoint = '/contributors';
    const chartData = [{ id: 'abc123', additions: 4, deletions: 2 }];

    beforeEach(() => {
      mock = new MockAdapter(axios);
      createAlert.mockClear();
    });

    afterEach(() => {
      mock.restore();
      jest.restoreAllMocks();
    });

    it('should commit SET_CHART_STATS with received response', () => {
      jest.spyOn(axios, 'get');
      mock.onGet(endpoint, { params: { with_stats: true } }).reply(HTTP_STATUS_OK, chartData);

      return testAction(
        actions.fetchChartStats,
        endpoint,
        { statsLoaded: false, statsLoading: false },
        [
          { type: types.SET_STATS_LOADING_STATE, payload: true },
          { type: types.SET_CHART_STATS, payload: chartData },
          { type: types.SET_STATS_LOADING_STATE, payload: false },
        ],
        [],
      ).then((result) => {
        expect(result).toBe(true);
        expect(axios.get).toHaveBeenCalledWith(endpoint, { params: { with_stats: true } });
      });
    });

    it.each([
      { statsLoaded: true, statsLoading: false },
      { statsLoaded: false, statsLoading: true },
    ])('should not fetch stats again with %j', async (state) => {
      jest.spyOn(axios, 'get');

      const result = await testAction(actions.fetchChartStats, endpoint, state, [], []);

      expect(result).toBe(true);
      expect(axios.get).not.toHaveBeenCalled();
    });

    it('should show alert on API error', async () => {
      mock.onGet(endpoint, { params: { with_stats: true } }).reply(HTTP_STATUS_BAD_REQUEST);

      const result = await testAction(
        actions.fetchChartStats,
        endpoint,
        { statsLoaded: false, statsLoading: false },
        [
          { type: types.SET_STATS_LOADING_STATE, payload: true },
          { type: types.SET_STATS_LOADING_STATE, payload: false },
        ],
        [],
      );

      expect(result).toBe(false);
      expect(createAlert).toHaveBeenCalledWith({
        message: expect.stringMatching('error'),
      });
    });
  });
});
