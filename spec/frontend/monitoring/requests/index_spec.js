import MockAdapter from 'axios-mock-adapter';
import { backoffMockImplementation } from 'helpers/backoff_helper';
import axios from '~/lib/utils/axios_utils';
import * as commonUtils from '~/lib/utils/common_utils';
import statusCodes from '~/lib/utils/http_status';
import { getDashboard, getPrometheusQueryData } from '~/monitoring/requests';
import { metricsDashboardResponse } from '../fixture_data';

describe('monitoring metrics_requests', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    jest.spyOn(commonUtils, 'backOff').mockImplementation(backoffMockImplementation);
  });

  afterEach(() => {
    mock.reset();

    commonUtils.backOff.mockReset();
  });

  describe('getDashboard', () => {
    const response = metricsDashboardResponse;
    const dashboardEndpoint = '/dashboard';
    const params = {
      start_time: 'start_time',
      end_time: 'end_time',
    };

    it('returns a dashboard response', () => {
      mock.onGet(dashboardEndpoint).reply(statusCodes.OK, response);

      return getDashboard(dashboardEndpoint, params).then((data) => {
        expect(data).toEqual(metricsDashboardResponse);
      });
    });

    it('returns a dashboard response after retrying twice', () => {
      mock.onGet(dashboardEndpoint).replyOnce(statusCodes.NO_CONTENT);
      mock.onGet(dashboardEndpoint).replyOnce(statusCodes.NO_CONTENT);
      mock.onGet(dashboardEndpoint).reply(statusCodes.OK, response);

      return getDashboard(dashboardEndpoint, params).then((data) => {
        expect(data).toEqual(metricsDashboardResponse);
        expect(mock.history.get).toHaveLength(3);
      });
    });

    it('rejects after getting an error', () => {
      mock.onGet(dashboardEndpoint).reply(500);

      return getDashboard(dashboardEndpoint, params).catch((error) => {
        expect(error).toEqual(expect.any(Error));
        expect(mock.history.get).toHaveLength(1);
      });
    });
  });

  describe('getPrometheusQueryData', () => {
    const response = {
      status: 'success',
      data: {
        resultType: 'matrix',
        result: [],
      },
    };
    const prometheusEndpoint = '/query_range';
    const params = {
      start_time: 'start_time',
      end_time: 'end_time',
    };

    it('returns a dashboard response', () => {
      mock.onGet(prometheusEndpoint).reply(statusCodes.OK, response);

      return getPrometheusQueryData(prometheusEndpoint, params).then((data) => {
        expect(data).toEqual(response.data);
      });
    });

    it('returns a dashboard response after retrying twice', () => {
      // Mock multiple attempts while the cache is filling up
      mock.onGet(prometheusEndpoint).replyOnce(statusCodes.NO_CONTENT);
      mock.onGet(prometheusEndpoint).replyOnce(statusCodes.NO_CONTENT);
      mock.onGet(prometheusEndpoint).reply(statusCodes.OK, response); // 3rd attempt

      return getPrometheusQueryData(prometheusEndpoint, params).then((data) => {
        expect(data).toEqual(response.data);
        expect(mock.history.get).toHaveLength(3);
      });
    });

    it('rejects after getting an HTTP 500 error', () => {
      mock.onGet(prometheusEndpoint).reply(500, {
        status: 'error',
        error: 'An error occurred',
      });

      return getPrometheusQueryData(prometheusEndpoint, params).catch((error) => {
        expect(error).toEqual(new Error('Request failed with status code 500'));
      });
    });

    it('rejects after retrying twice and getting an HTTP 401 error', () => {
      // Mock multiple attempts while the cache is filling up and fails
      mock.onGet(prometheusEndpoint).reply(statusCodes.UNAUTHORIZED, {
        status: 'error',
        error: 'An error occurred',
      });

      return getPrometheusQueryData(prometheusEndpoint, params).catch((error) => {
        expect(error).toEqual(new Error('Request failed with status code 401'));
      });
    });

    it('rejects after retrying twice and getting an HTTP 500 error', () => {
      // Mock multiple attempts while the cache is filling up and fails
      mock.onGet(prometheusEndpoint).replyOnce(statusCodes.NO_CONTENT);
      mock.onGet(prometheusEndpoint).replyOnce(statusCodes.NO_CONTENT);
      mock.onGet(prometheusEndpoint).reply(500, {
        status: 'error',
        error: 'An error occurred',
      }); // 3rd attempt

      return getPrometheusQueryData(prometheusEndpoint, params).catch((error) => {
        expect(error).toEqual(new Error('Request failed with status code 500'));
        expect(mock.history.get).toHaveLength(3);
      });
    });

    test.each`
      code                                | reason
      ${statusCodes.BAD_REQUEST}          | ${'Parameters are missing or incorrect'}
      ${statusCodes.UNPROCESSABLE_ENTITY} | ${"Expression can't be executed"}
      ${statusCodes.SERVICE_UNAVAILABLE}  | ${'Query timed out or aborted'}
    `('rejects with details: "$reason" after getting an HTTP $code error', ({ code, reason }) => {
      mock.onGet(prometheusEndpoint).reply(code, {
        status: 'error',
        error: reason,
      });

      return getPrometheusQueryData(prometheusEndpoint, params).catch((error) => {
        expect(error).toEqual(new Error(reason));
        expect(mock.history.get).toHaveLength(1);
      });
    });
  });
});
