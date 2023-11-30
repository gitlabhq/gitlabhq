import MockAdapter from 'axios-mock-adapter';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { buildClient } from '~/observability/client';
import axios from '~/lib/utils/axios_utils';
import { logError } from '~/lib/logger';
import { DEFAULT_SORTING_OPTION, SORTING_OPTIONS } from '~/observability/constants';

jest.mock('~/lib/utils/axios_utils');
jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/logger');

describe('buildClient', () => {
  let client;
  let axiosMock;

  const tracingUrl = 'https://example.com/tracing';
  const provisioningUrl = 'https://example.com/provisioning';
  const servicesUrl = 'https://example.com/services';
  const operationsUrl = 'https://example.com/services/$SERVICE_NAME$/operations';
  const metricsUrl = 'https://example.com/metrics';
  const FETCHING_TRACES_ERROR = 'traces are missing/invalid in the response';

  const apiConfig = {
    tracingUrl,
    provisioningUrl,
    servicesUrl,
    operationsUrl,
    metricsUrl,
  };

  const getQueryParam = () => decodeURIComponent(axios.get.mock.calls[0][1].params.toString());

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    jest.spyOn(axios, 'get');

    client = buildClient(apiConfig);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  const expectErrorToBeReported = (e) => {
    expect(Sentry.captureException).toHaveBeenCalledWith(e);
    expect(logError).toHaveBeenCalledWith(e);
  };

  describe('buildClient', () => {
    it('throws is option is missing', () => {
      expect(() => buildClient()).toThrow(new Error('No options object provided'));
    });
    it.each(Object.keys(apiConfig))('throws if %s is missing', (param) => {
      const e = new Error(`${param} param must be a string`);

      expect(() =>
        buildClient({
          ...apiConfig,
          [param]: undefined,
        }),
      ).toThrow(e);
    });
  });

  describe('isObservabilityEnabled', () => {
    it('returns true if requests succeedes', async () => {
      axiosMock.onGet(provisioningUrl).reply(200, {
        status: 'ready',
      });

      const enabled = await client.isObservabilityEnabled();

      expect(enabled).toBe(true);
    });

    it('returns false if response is 404', async () => {
      axiosMock.onGet(provisioningUrl).reply(404);

      const enabled = await client.isObservabilityEnabled();

      expect(enabled).toBe(false);
    });

    // we currently ignore the 'status' payload and just check if the request was successful
    // We might improve this as part of https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2315
    it('returns true for any status', async () => {
      axiosMock.onGet(provisioningUrl).reply(200, {
        status: 'not ready',
      });

      const enabled = await client.isObservabilityEnabled();

      expect(enabled).toBe(true);
    });

    it('throws in case of any non-404 error', async () => {
      axiosMock.onGet(provisioningUrl).reply(500);

      const e = 'Request failed with status code 500';
      await expect(client.isObservabilityEnabled()).rejects.toThrow(e);
      expectErrorToBeReported(new Error(e));
    });

    it('throws in case of unexpected response', async () => {
      axiosMock.onGet(provisioningUrl).reply(200, {});

      const e = 'Failed to check provisioning';
      await expect(client.isObservabilityEnabled()).rejects.toThrow(e);
      expectErrorToBeReported(new Error(e));
    });
  });

  describe('enableObservability', () => {
    it('makes a PUT request to the provisioning URL', async () => {
      let putConfig;
      axiosMock.onPut(provisioningUrl).reply((config) => {
        putConfig = config;
        return [200];
      });

      await client.enableObservability();

      expect(putConfig.withCredentials).toBe(true);
    });

    it('reports an error if the req fails', async () => {
      axiosMock.onPut(provisioningUrl).reply(401);

      const e = 'Request failed with status code 401';

      await expect(client.enableObservability()).rejects.toThrow(e);
      expectErrorToBeReported(new Error(e));
    });
  });

  describe('fetchTrace', () => {
    it('fetches the trace from the tracing URL', async () => {
      const mockTrace = {
        trace_id: 'trace-1',
        duration_nano: 3000,
        spans: [{ duration_nano: 1000 }, { duration_nano: 2000 }],
      };
      axiosMock.onGet(`${tracingUrl}/trace-1`).reply(200, mockTrace);

      const result = await client.fetchTrace('trace-1');

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(`${tracingUrl}/trace-1`, {
        withCredentials: true,
      });
      expect(result).toEqual(mockTrace);
    });

    it('rejects if trace id is missing', () => {
      return expect(client.fetchTrace()).rejects.toThrow('traceId is required.');
    });
  });

  describe('fetchTraces', () => {
    it('fetches traces from the tracing URL', async () => {
      const mockResponse = {
        traces: [
          {
            trace_id: 'trace-1',
            duration_nano: 3000,
            spans: [{ duration_nano: 1000 }, { duration_nano: 2000 }],
          },
          { trace_id: 'trace-2', duration_nano: 3000, spans: [{ duration_nano: 2000 }] },
        ],
      };

      axiosMock.onGet(tracingUrl).reply(200, mockResponse);

      const result = await client.fetchTraces();

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(tracingUrl, {
        withCredentials: true,
        params: expect.any(URLSearchParams),
      });
      expect(result).toEqual(mockResponse);
    });

    it('rejects if traces are missing', async () => {
      axiosMock.onGet(tracingUrl).reply(200, {});

      await expect(client.fetchTraces()).rejects.toThrow(FETCHING_TRACES_ERROR);
      expectErrorToBeReported(new Error(FETCHING_TRACES_ERROR));
    });

    it('rejects if traces are invalid', async () => {
      axiosMock.onGet(tracingUrl).reply(200, { traces: 'invalid' });

      await expect(client.fetchTraces()).rejects.toThrow(FETCHING_TRACES_ERROR);
      expectErrorToBeReported(new Error(FETCHING_TRACES_ERROR));
    });

    describe('sort order', () => {
      beforeEach(() => {
        axiosMock.onGet(tracingUrl).reply(200, {
          traces: [],
        });
      });
      it('appends sort param if specified', async () => {
        await client.fetchTraces({ sortBy: SORTING_OPTIONS.DURATION_DESC });

        expect(getQueryParam()).toBe(`sort=${SORTING_OPTIONS.DURATION_DESC}`);
      });

      it('defaults to DEFAULT_SORTING_OPTION if no sortBy param is specified', async () => {
        await client.fetchTraces();

        expect(getQueryParam()).toBe(`sort=${DEFAULT_SORTING_OPTION}`);
      });

      it('defaults to timestamp_desc if sortBy param is not an accepted value', async () => {
        await client.fetchTraces({ sortBy: 'foo-bar' });

        expect(getQueryParam()).toBe(`sort=${SORTING_OPTIONS.TIMESTAMP_DESC}`);
      });
    });

    describe('query filter', () => {
      beforeEach(() => {
        axiosMock.onGet(tracingUrl).reply(200, {
          traces: [],
        });
      });

      it('does not set any query param without filters', async () => {
        await client.fetchTraces();

        expect(getQueryParam()).toBe(`sort=${SORTING_OPTIONS.TIMESTAMP_DESC}`);
      });

      it('appends page_token if specified', async () => {
        await client.fetchTraces({ pageToken: 'page-token' });

        expect(getQueryParam()).toContain('page_token=page-token');
      });

      it('appends page_size if specified', async () => {
        await client.fetchTraces({ pageSize: 10 });

        expect(getQueryParam()).toContain('page_size=10');
      });

      it('converts filter to proper query params', async () => {
        await client.fetchTraces({
          filters: {
            durationMs: [
              { operator: '>', value: '100' },
              { operator: '<', value: '1000' },
            ],
            operation: [
              { operator: '=', value: 'op' },
              { operator: '!=', value: 'not-op' },
            ],
            service: [
              { operator: '=', value: 'service' },
              { operator: '!=', value: 'not-service' },
            ],
            period: [{ operator: '=', value: '5m' }],
            traceId: [
              { operator: '=', value: 'trace-id' },
              { operator: '!=', value: 'not-trace-id' },
            ],
            attribute: [{ operator: '=', value: 'name1=value1' }],
          },
        });
        expect(getQueryParam()).toContain(
          'gt[duration_nano]=100000000&lt[duration_nano]=1000000000' +
            '&operation=op&not[operation]=not-op' +
            '&service_name=service&not[service_name]=not-service' +
            '&period=5m' +
            '&trace_id=trace-id&not[trace_id]=not-trace-id' +
            '&attr_name=name1&attr_value=value1',
        );
      });

      it('handles repeated params', async () => {
        await client.fetchTraces({
          filters: {
            operation: [
              { operator: '=', value: 'op' },
              { operator: '=', value: 'op2' },
            ],
          },
        });
        expect(getQueryParam()).toContain('operation=op&operation=op2');
      });

      it('ignores unsupported filters', async () => {
        await client.fetchTraces({
          filters: {
            unsupportedFilter: [{ operator: '=', value: 'foo' }],
          },
        });

        expect(getQueryParam()).toBe(`sort=${SORTING_OPTIONS.TIMESTAMP_DESC}`);
      });

      it('ignores empty filters', async () => {
        await client.fetchTraces({
          filters: {
            durationMs: null,
            traceId: undefined,
          },
        });

        expect(getQueryParam()).toBe(`sort=${SORTING_OPTIONS.TIMESTAMP_DESC}`);
      });

      it('ignores non-array filters', async () => {
        await client.fetchTraces({
          filters: {
            traceId: { operator: '=', value: 'foo' },
          },
        });

        expect(getQueryParam()).toBe(`sort=${SORTING_OPTIONS.TIMESTAMP_DESC}`);
      });

      it('ignores unsupported operators', async () => {
        await client.fetchTraces({
          filters: {
            durationMs: [
              { operator: '*', value: 'foo' },
              { operator: '=', value: 'foo' },
              { operator: '!=', value: 'foo' },
            ],
            operation: [
              { operator: '>', value: 'foo' },
              { operator: '<', value: 'foo' },
            ],
            service: [
              { operator: '>', value: 'foo' },
              { operator: '<', value: 'foo' },
            ],
            period: [{ operator: '!=', value: 'foo' }],
            traceId: [
              { operator: '>', value: 'foo' },
              { operator: '<', value: 'foo' },
            ],
          },
        });

        expect(getQueryParam()).toBe(`sort=${SORTING_OPTIONS.TIMESTAMP_DESC}`);
      });
    });
  });

  describe('fetchServices', () => {
    it('fetches services from the services URL', async () => {
      const mockResponse = {
        services: [{ name: 'service-1' }, { name: 'service-2' }],
      };

      axiosMock.onGet(servicesUrl).reply(200, mockResponse);

      const result = await client.fetchServices();

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(servicesUrl, {
        withCredentials: true,
      });
      expect(result).toEqual(mockResponse.services);
    });

    it('rejects if services are missing', async () => {
      axiosMock.onGet(servicesUrl).reply(200, {});

      const e = 'failed to fetch services. invalid response';
      await expect(client.fetchServices()).rejects.toThrow(e);
      expectErrorToBeReported(new Error(e));
    });
  });

  describe('fetchOperations', () => {
    const serviceName = 'test-service';
    const parsedOperationsUrl = `https://example.com/services/${serviceName}/operations`;

    it('fetches operations from the operations URL', async () => {
      const mockResponse = {
        operations: [{ name: 'operation-1' }, { name: 'operation-2' }],
      };

      axiosMock.onGet(parsedOperationsUrl).reply(200, mockResponse);

      const result = await client.fetchOperations(serviceName);

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(parsedOperationsUrl, {
        withCredentials: true,
      });
      expect(result).toEqual(mockResponse.operations);
    });

    it('rejects if serviceName is missing', async () => {
      const e = 'fetchOperations() - serviceName is required.';
      await expect(client.fetchOperations()).rejects.toThrow(e);
      expectErrorToBeReported(new Error(e));
    });

    it('rejects if operationUrl does not contain $SERVICE_NAME$', async () => {
      client = buildClient({
        ...apiConfig,
        operationsUrl: 'something',
      });
      const e = 'fetchOperations() - operationsUrl must contain $SERVICE_NAME$';
      await expect(client.fetchOperations(serviceName)).rejects.toThrow(e);
      expectErrorToBeReported(new Error(e));
    });

    it('rejects if operations are missing', async () => {
      axiosMock.onGet(parsedOperationsUrl).reply(200, {});

      const e = 'failed to fetch operations. invalid response';
      await expect(client.fetchOperations(serviceName)).rejects.toThrow(e);
      expectErrorToBeReported(new Error(e));
    });
  });

  describe('fetchMetrics', () => {
    const FETCHING_METRICS_ERROR = 'metrics are missing/invalid in the response';

    it('fetches metrics from the metrics URL', async () => {
      const mockResponse = {
        metrics: [
          { name: 'metric A', description: 'a counter metric called A', type: 'COUNTER' },
          { name: 'metric B', description: 'a gauge metric called B', type: 'GAUGE' },
        ],
      };

      axiosMock.onGet(metricsUrl).reply(200, mockResponse);

      const result = await client.fetchMetrics();

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(metricsUrl, {
        withCredentials: true,
        params: expect.any(URLSearchParams),
      });
      expect(result).toEqual(mockResponse);
    });

    describe('query filter', () => {
      beforeEach(() => {
        axiosMock.onGet(metricsUrl).reply(200, {
          metrics: [],
        });
      });

      it('does not set any query param without filters', async () => {
        await client.fetchMetrics();

        expect(getQueryParam()).toBe('');
      });

      it('sets the start_with query param based on the search filter', async () => {
        await client.fetchMetrics({
          filters: { search: [{ value: 'foo' }, { value: 'bar' }, { value: ' ' }] },
        });
        expect(getQueryParam()).toBe('starts_with=foo+bar');
      });

      it('ignores empty search', async () => {
        await client.fetchMetrics({
          filters: {
            search: [{ value: ' ' }, { value: '' }, { value: null }, { value: undefined }],
          },
        });
        expect(getQueryParam()).toBe('');
      });

      it('ignores unsupported filters', async () => {
        await client.fetchMetrics({
          filters: {
            unsupportedFilter: [{ operator: '=', value: 'foo' }],
          },
        });

        expect(getQueryParam()).toBe('');
      });

      it('ignores non-array search filters', async () => {
        await client.fetchMetrics({
          filters: {
            search: { value: 'foo' },
          },
        });

        expect(getQueryParam()).toBe('');
      });

      it('adds the search limit param if specified with the search filter', async () => {
        await client.fetchMetrics({
          filters: { search: [{ value: 'foo' }] },
          limit: 50,
        });
        expect(getQueryParam()).toBe('starts_with=foo&limit=50');
      });

      it('does not add the search limit param if the search filter is missing', async () => {
        await client.fetchMetrics({
          limit: 50,
        });
        expect(getQueryParam()).toBe('');
      });

      it('does not add the search limit param if the search filter is empty', async () => {
        await client.fetchMetrics({
          limit: 50,
          search: [{ value: ' ' }, { value: '' }, { value: null }, { value: undefined }],
        });
        expect(getQueryParam()).toBe('');
      });
    });

    it('rejects if metrics are missing', async () => {
      axiosMock.onGet(metricsUrl).reply(200, {});

      await expect(client.fetchMetrics()).rejects.toThrow(FETCHING_METRICS_ERROR);
      expectErrorToBeReported(new Error(FETCHING_METRICS_ERROR));
    });

    it('rejects if metrics are invalid', async () => {
      axiosMock.onGet(metricsUrl).reply(200, { traces: 'invalid' });

      await expect(client.fetchMetrics()).rejects.toThrow(FETCHING_METRICS_ERROR);
      expectErrorToBeReported(new Error(FETCHING_METRICS_ERROR));
    });
  });
});
