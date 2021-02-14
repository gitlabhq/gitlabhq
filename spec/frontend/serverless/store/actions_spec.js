import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import statusCodes from '~/lib/utils/http_status';
import { fetchFunctions, fetchMetrics } from '~/serverless/store/actions';
import { mockServerlessFunctions, mockMetrics } from '../mock_data';
import { adjustMetricQuery } from '../utils';

describe('ServerlessActions', () => {
  describe('fetchFunctions', () => {
    it('should successfully fetch functions', (done) => {
      const endpoint = '/functions';
      const mock = new MockAdapter(axios);
      mock.onGet(endpoint).reply(statusCodes.OK, JSON.stringify(mockServerlessFunctions));

      testAction(
        fetchFunctions,
        { functionsPath: endpoint },
        {},
        [],
        [
          { type: 'requestFunctionsLoading' },
          { type: 'receiveFunctionsSuccess', payload: mockServerlessFunctions },
        ],
        () => {
          mock.restore();
          done();
        },
      );
    });

    it('should successfully retry', (done) => {
      const endpoint = '/functions';
      const mock = new MockAdapter(axios);
      mock
        .onGet(endpoint)
        .reply(() => new Promise((resolve) => setTimeout(() => resolve(200), Infinity)));

      testAction(
        fetchFunctions,
        { functionsPath: endpoint },
        {},
        [],
        [{ type: 'requestFunctionsLoading' }],
        () => {
          mock.restore();
          done();
        },
      );
    });
  });

  describe('fetchMetrics', () => {
    it('should return no prometheus', (done) => {
      const endpoint = '/metrics';
      const mock = new MockAdapter(axios);
      mock.onGet(endpoint).reply(statusCodes.NO_CONTENT);

      testAction(
        fetchMetrics,
        { metricsPath: endpoint, hasPrometheus: false },
        {},
        [],
        [{ type: 'receiveMetricsNoPrometheus' }],
        () => {
          mock.restore();
          done();
        },
      );
    });

    it('should successfully fetch metrics', (done) => {
      const endpoint = '/metrics';
      const mock = new MockAdapter(axios);
      mock.onGet(endpoint).reply(statusCodes.OK, JSON.stringify(mockMetrics));

      testAction(
        fetchMetrics,
        { metricsPath: endpoint, hasPrometheus: true },
        {},
        [],
        [{ type: 'receiveMetricsSuccess', payload: adjustMetricQuery(mockMetrics) }],
        () => {
          mock.restore();
          done();
        },
      );
    });
  });
});
