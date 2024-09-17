import MockAdapter from 'axios-mock-adapter';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { buildClient } from '~/observability/client';
import axios from '~/lib/utils/axios_utils';
import { logError } from '~/lib/logger';
import { DEFAULT_SORTING_OPTION, SORTING_OPTIONS } from '~/observability/constants';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/lib/utils/axios_utils');
jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/logger');

describe('buildClient', () => {
  let client;
  let axiosMock;

  const tracingUrl = 'https://example.com/tracing';
  const tracingAnalyticsUrl = 'https://example.com/tracing/analytics';
  const servicesUrl = 'https://example.com/services';
  const operationsUrl = 'https://example.com/services/$SERVICE_NAME$/operations';
  const metricsUrl = 'https://example.com/metrics';
  const metricsSearchUrl = 'https://example.com/metrics/search';
  const metricsSearchMetadataUrl = 'https://example.com/metrics/searchmetadata';
  const logsSearchUrl = 'https://example.com/metrics/logs/search';
  const logsSearchMetadataUrl = 'https://example.com/metrics/logs/search';
  const analyticsUrl = 'https://example.com/analytics';
  const FETCHING_TRACES_ERROR = 'traces are missing/invalid in the response';

  const apiConfig = {
    tracingUrl,
    tracingAnalyticsUrl,
    servicesUrl,
    operationsUrl,
    metricsUrl,
    metricsSearchUrl,
    metricsSearchMetadataUrl,
    logsSearchUrl,
    logsSearchMetadataUrl,
    analyticsUrl,
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

  describe('fetchTrace', () => {
    it('fetches the trace from the tracing URL', async () => {
      const mockTrace = {
        trace_id: 'trace-1',
        duration_nano: 3000,
        spans: [{ duration_nano: 1000 }, { duration_nano: 2000 }],
      };
      axiosMock.onGet(`${tracingUrl}/trace-1`).reply(HTTP_STATUS_OK, mockTrace);

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

      axiosMock.onGet(tracingUrl).reply(HTTP_STATUS_OK, mockResponse);

      const result = await client.fetchTraces();

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(tracingUrl, {
        withCredentials: true,
        params: expect.any(URLSearchParams),
      });
      expect(result).toEqual(mockResponse);
    });

    it('rejects if traces are missing', async () => {
      axiosMock.onGet(tracingUrl).reply(HTTP_STATUS_OK, {});

      await expect(client.fetchTraces()).rejects.toThrow(FETCHING_TRACES_ERROR);
      expectErrorToBeReported(new Error(FETCHING_TRACES_ERROR));
    });

    it('rejects if traces are invalid', async () => {
      axiosMock.onGet(tracingUrl).reply(HTTP_STATUS_OK, { traces: 'invalid' });

      await expect(client.fetchTraces()).rejects.toThrow(FETCHING_TRACES_ERROR);
      expectErrorToBeReported(new Error(FETCHING_TRACES_ERROR));
    });

    it('passes the abort controller to axios', async () => {
      axiosMock.onGet(tracingUrl).reply(HTTP_STATUS_OK, { traces: [] });

      const abortController = new AbortController();
      await client.fetchTraces({ abortController });

      expect(axios.get).toHaveBeenCalledWith(tracingUrl, {
        withCredentials: true,
        params: expect.any(URLSearchParams),
        signal: abortController.signal,
      });
    });

    describe('sort order', () => {
      beforeEach(() => {
        axiosMock.onGet(tracingUrl).reply(HTTP_STATUS_OK, {
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
        axiosMock.onGet(tracingUrl).reply(HTTP_STATUS_OK, {
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

      describe('date range filter', () => {
        it('handle predefined date range value', async () => {
          await client.fetchTraces({
            filters: { dateRange: { value: '5m' } },
          });
          expect(getQueryParam()).toContain(`period=5m`);
        });

        it('handle custom date range value', async () => {
          await client.fetchTraces({
            filters: {
              dateRange: {
                endDate: new Date('2023-04-01T12:00:00'),
                startDate: new Date('2023-04-01T00:00:00'),
                value: 'custom',
              },
            },
          });
          expect(getQueryParam()).toContain(
            'start_time=2023-04-01T00:00:00.000Z&end_time=2023-04-01T12:00:00.000Z',
          );
        });

        it('fails if the date range is larger than 12h', async () => {
          await expect(
            client.fetchTraces({
              filters: {
                dateRange: {
                  endDate: new Date('2023-04-01T12:00:01'),
                  startDate: new Date('2023-04-01T00:00:00'),
                  value: 'custom',
                },
              },
            }),
          ).rejects.toThrow();
        });
      });

      describe('attributes filters', () => {
        it('converts filter to proper query params', async () => {
          await client.fetchTraces({
            filters: {
              attributes: {
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
                status: [
                  { operator: '=', value: 'ok' },
                  { operator: '!=', value: 'error' },
                ],
                traceId: [
                  { operator: '=', value: 'trace-id' },
                  { operator: '!=', value: 'not-trace-id' },
                ],
                attribute: [{ operator: '=', value: 'name1=value1' }],
              },
            },
          });
          expect(getQueryParam()).toContain(
            'gt[duration_nano]=100000000&lt[duration_nano]=1000000000' +
              '&operation=op&not[operation]=not-op' +
              '&service_name=service&not[service_name]=not-service' +
              '&trace_id=trace-id&not[trace_id]=not-trace-id' +
              '&attr_name=name1&attr_value=value1' +
              '&status=ok&not[status]=error',
          );
        });

        it('ignores unsupported filters', async () => {
          await client.fetchTraces({
            filters: {
              attributes: {
                unsupportedFilter: [{ operator: '=', value: 'foo' }],
              },
            },
          });

          expect(getQueryParam()).toBe(`sort=${SORTING_OPTIONS.TIMESTAMP_DESC}`);
        });

        it('ignores empty filters', async () => {
          await client.fetchTraces({
            filters: {
              attributes: {
                durationMs: null,
                traceId: undefined,
              },
            },
          });

          expect(getQueryParam()).toBe(`sort=${SORTING_OPTIONS.TIMESTAMP_DESC}`);
        });

        it('ignores non-array filters', async () => {
          await client.fetchTraces({
            filters: {
              attributes: {
                traceId: { operator: '=', value: 'foo' },
              },
            },
          });

          expect(getQueryParam()).toBe(`sort=${SORTING_OPTIONS.TIMESTAMP_DESC}`);
        });

        it('ignores unsupported operators', async () => {
          await client.fetchTraces({
            filters: {
              attributes: {
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
                traceId: [
                  { operator: '>', value: 'foo' },
                  { operator: '<', value: 'foo' },
                ],
              },
            },
          });

          expect(getQueryParam()).toBe(`sort=${SORTING_OPTIONS.TIMESTAMP_DESC}`);
        });
      });
    });
  });

  describe('fetchTracesAnalytics', () => {
    it('fetches analytics from the tracesAnalytics URL', async () => {
      const mockResponse = {
        results: [
          {
            Interval: 1705039800,
            count: 5,
            p90_duration_nano: 50613502867,
            p95_duration_nano: 50613502867,
            p75_duration_nano: 49756727928,
            p50_duration_nano: 41610120929,
            error_count: 324,
            trace_rate: 2.576111111111111,
            error_rate: 0.09,
          },
        ],
      };

      axiosMock.onGet(tracingAnalyticsUrl).reply(HTTP_STATUS_OK, mockResponse);

      const result = await client.fetchTracesAnalytics();

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(tracingAnalyticsUrl, {
        withCredentials: true,
        params: expect.any(URLSearchParams),
      });
      expect(result).toEqual(mockResponse.results);
    });

    it('returns empty array if analytics are missing', async () => {
      axiosMock.onGet(tracingAnalyticsUrl).reply(HTTP_STATUS_OK, {});

      expect(await client.fetchTracesAnalytics()).toEqual([]);
    });

    it('passes the abort controller to axios', async () => {
      axiosMock.onGet(tracingAnalyticsUrl).reply(HTTP_STATUS_OK, {});

      const abortController = new AbortController();
      await client.fetchTracesAnalytics({ abortController });

      expect(axios.get).toHaveBeenCalledWith(tracingAnalyticsUrl, {
        withCredentials: true,
        params: expect.any(URLSearchParams),
        signal: abortController.signal,
      });
    });

    describe('query filter', () => {
      beforeEach(() => {
        axiosMock.onGet(tracingAnalyticsUrl).reply(HTTP_STATUS_OK, {
          results: [],
        });
      });

      it('does not set any query param without filters', async () => {
        await client.fetchTracesAnalytics();

        expect(getQueryParam()).toBe(``);
      });

      describe('date range filter', () => {
        it('handle predefined date range value', async () => {
          await client.fetchTracesAnalytics({
            filters: { dateRange: { value: '5m' } },
          });
          expect(getQueryParam()).toContain(`period=5m`);
        });

        it('handle custom date range value', async () => {
          await client.fetchTracesAnalytics({
            filters: {
              dateRange: {
                endDate: new Date('2020-07-06'),
                startDate: new Date('2020-07-05'),
                value: 'custom',
              },
            },
          });
          expect(getQueryParam()).toContain(
            'start_time=2020-07-05T00:00:00.000Z&end_time=2020-07-06T00:00:00.000Z',
          );
        });
      });

      describe('attributes filters', () => {
        it('converts filter to proper query params', async () => {
          await client.fetchTracesAnalytics({
            filters: {
              attributes: {
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
                status: [
                  { operator: '=', value: 'ok' },
                  { operator: '!=', value: 'error' },
                ],
                traceId: [
                  { operator: '=', value: 'trace-id' },
                  { operator: '!=', value: 'not-trace-id' },
                ],
                attribute: [{ operator: '=', value: 'name1=value1' }],
              },
            },
          });
          expect(getQueryParam()).toContain(
            'gt[duration_nano]=100000000&lt[duration_nano]=1000000000' +
              '&operation=op&not[operation]=not-op' +
              '&service_name=service&not[service_name]=not-service' +
              '&trace_id=trace-id&not[trace_id]=not-trace-id' +
              '&attr_name=name1&attr_value=value1' +
              '&status=ok&not[status]=error',
          );
        });

        it('ignores unsupported filters', async () => {
          await client.fetchTracesAnalytics({
            filters: {
              attributes: {
                unsupportedFilter: [{ operator: '=', value: 'foo' }],
              },
            },
          });

          expect(getQueryParam()).toBe(``);
        });

        it('ignores empty filters', async () => {
          await client.fetchTracesAnalytics({
            filters: {
              attributes: {
                durationMs: null,
                traceId: undefined,
              },
            },
          });

          expect(getQueryParam()).toBe(``);
        });

        it('ignores non-array filters', async () => {
          await client.fetchTracesAnalytics({
            filters: {
              attributes: {
                traceId: { operator: '=', value: 'foo' },
              },
            },
          });

          expect(getQueryParam()).toBe(``);
        });

        it('ignores unsupported operators', async () => {
          await client.fetchTracesAnalytics({
            filters: {
              attributes: {
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
                traceId: [
                  { operator: '>', value: 'foo' },
                  { operator: '<', value: 'foo' },
                ],
              },
            },
          });

          expect(getQueryParam()).toBe(``);
        });
      });
    });
  });

  describe('fetchServices', () => {
    it('fetches services from the services URL', async () => {
      const mockResponse = {
        services: [{ name: 'service-1' }, { name: 'service-2' }],
      };

      axiosMock.onGet(servicesUrl).reply(HTTP_STATUS_OK, mockResponse);

      const result = await client.fetchServices();

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(servicesUrl, {
        withCredentials: true,
      });
      expect(result).toEqual(mockResponse.services);
    });

    it('rejects if services are missing', async () => {
      axiosMock.onGet(servicesUrl).reply(HTTP_STATUS_OK, {});

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

      axiosMock.onGet(parsedOperationsUrl).reply(HTTP_STATUS_OK, mockResponse);

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
      axiosMock.onGet(parsedOperationsUrl).reply(HTTP_STATUS_OK, {});

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
          {
            name: 'metric A',
            description: 'a counter metric called A',
            type: 'COUNTER',
            attributes: [],
          },
          {
            name: 'metric B',
            description: 'a gauge metric called B',
            type: 'GAUGE',
            attributes: [],
          },
        ],
      };

      axiosMock.onGet(metricsUrl).reply(HTTP_STATUS_OK, mockResponse);

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
        axiosMock.onGet(metricsUrl).reply(HTTP_STATUS_OK, {
          metrics: [],
        });
      });

      it('does not set any query param without filters', async () => {
        await client.fetchMetrics();

        expect(getQueryParam()).toBe('');
      });

      it('sets the search query param based on the search filter', async () => {
        await client.fetchMetrics({
          filters: { search: [{ value: 'foo' }, { value: 'bar' }] },
        });
        expect(getQueryParam()).toBe('search=foo&search=bar');
      });

      it('ignores empty search', async () => {
        await client.fetchMetrics({
          filters: {
            search: [{ value: '' }, { value: null }, { value: undefined }],
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
        expect(getQueryParam()).toBe('search=foo&limit=50');
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

      it('handles attributes filter', async () => {
        await client.fetchMetrics({
          filters: {
            attribute: [
              { value: 'foo.bar', operator: '=' },
              { value: 'foo.baz', operator: '=' },
              { value: 'not-supported', operator: '!=' },
            ],
            traceId: [
              { operator: '=', value: 'traceId' },
              { operator: '=', value: 'traceId2' },
            ],
            unsupported: [{ value: 'foo.bar', operator: '=' }],
          },
        });
        expect(getQueryParam()).toBe(
          'attributes=foo.bar&attributes=foo.baz&trace_id=traceId&trace_id=traceId2',
        );
      });
    });

    it('rejects if metrics are missing', async () => {
      axiosMock.onGet(metricsUrl).reply(HTTP_STATUS_OK, {});

      await expect(client.fetchMetrics()).rejects.toThrow(FETCHING_METRICS_ERROR);
      expectErrorToBeReported(new Error(FETCHING_METRICS_ERROR));
    });

    it('rejects if metrics are invalid', async () => {
      axiosMock.onGet(metricsUrl).reply(HTTP_STATUS_OK, { traces: 'invalid' });

      await expect(client.fetchMetrics()).rejects.toThrow(FETCHING_METRICS_ERROR);
      expectErrorToBeReported(new Error(FETCHING_METRICS_ERROR));
    });
  });

  describe('fetchMetric', () => {
    it('fetches the metric from the API', async () => {
      const data = { results: [] };
      axiosMock.onGet(metricsSearchUrl).reply(HTTP_STATUS_OK, data);

      const result = await client.fetchMetric('name', 'type');

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(metricsSearchUrl, {
        withCredentials: true,
        params: new URLSearchParams({ mname: 'name', mtype: 'type' }),
      });
      expect(result).toEqual(data.results);
    });

    it('passes the abort controller to axios', async () => {
      axiosMock.onGet(metricsSearchUrl).reply(HTTP_STATUS_OK, { results: [] });

      const abortController = new AbortController();
      await client.fetchMetric('name', 'type', { abortController });

      expect(axios.get).toHaveBeenCalledWith(metricsSearchUrl, {
        withCredentials: true,
        params: new URLSearchParams({ mname: 'name', mtype: 'type' }),
        signal: abortController.signal,
      });
    });

    it('sets the visual param when specified', async () => {
      axiosMock.onGet(metricsSearchUrl).reply(HTTP_STATUS_OK, { results: [] });

      await client.fetchMetric('name', 'type', { visual: 'heatmap' });

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(metricsSearchUrl, {
        withCredentials: true,
        params: new URLSearchParams({ mname: 'name', mtype: 'type', mvisual: 'heatmap' }),
      });
    });

    describe('query filter params', () => {
      beforeEach(() => {
        axiosMock.onGet(metricsSearchUrl).reply(HTTP_STATUS_OK, { results: [] });
      });

      describe('attribute filter', () => {
        it('converts filter to proper query params', async () => {
          await client.fetchMetric('name', 'type', {
            filters: {
              attributes: {
                attr_1: [
                  { operator: '=', value: 'foo' },
                  { operator: '!=', value: 'bar' },
                ],
                attr_2: [
                  { operator: '=~', value: 'foo' },
                  { operator: '!~', value: 'bar' },
                ],
              },
            },
          });
          expect(getQueryParam()).toBe(
            'mname=name&mtype=type' +
              '&attrs=attr_1,eq,foo' +
              '&attrs=attr_1,neq,bar' +
              '&attrs=attr_2,re,foo' +
              '&attrs=attr_2,nre,bar',
          );
        });

        it('ignores empty filters', async () => {
          await client.fetchMetric('name', 'type', {
            filters: { attributes: [] },
          });

          expect(getQueryParam()).toBe('mname=name&mtype=type');
        });

        it('ignores undefined dimension filters', async () => {
          await client.fetchMetric('name', 'type', {
            filters: { attributes: undefined },
          });

          expect(getQueryParam()).toBe('mname=name&mtype=type');
        });

        it('ignores non-array filters', async () => {
          await client.fetchMetric('name', 'type', {
            filters: {
              attributes: {
                attr_1: { operator: '=', value: 'foo' },
              },
            },
          });

          expect(getQueryParam()).toBe('mname=name&mtype=type');
        });

        it('ignores unsupported operators', async () => {
          await client.fetchMetric('name', 'type', {
            filters: {
              attributes: {
                attr_1: [
                  { operator: '*', value: 'foo' },
                  { operator: '>', value: 'foo' },
                  { operator: '<', value: 'foo' },
                ],
              },
            },
          });

          expect(getQueryParam()).toBe('mname=name&mtype=type');
        });

        it('ignores undefined filters', async () => {
          await client.fetchMetric('name', 'type', {
            filters: undefined,
          });

          expect(getQueryParam()).toBe('mname=name&mtype=type');
        });

        it('ignores null filters', async () => {
          await client.fetchMetric('name', 'type', {
            filters: null,
          });

          expect(getQueryParam()).toBe('mname=name&mtype=type');
        });
      });

      describe('date range filter', () => {
        it('handle predefined date range value', async () => {
          await client.fetchMetric('name', 'type', {
            filters: { dateRange: { value: '5m' } },
          });
          expect(getQueryParam()).toContain(`period=5m`);
        });

        it('handle custom date range value', async () => {
          await client.fetchMetric('name', 'type', {
            filters: {
              dateRange: {
                endDate: new Date('2020-07-06'),
                startDate: new Date('2020-07-05'),
                value: 'custom',
              },
            },
          });
          expect(getQueryParam()).toContain(
            'start_time=2020-07-05T00:00:00.000Z&end_time=2020-07-06T00:00:00.000Z',
          );
        });
      });

      it('ignores empty filter', async () => {
        await client.fetchMetric('name', 'type', {
          filters: { dateRange: {} },
        });
        expect(getQueryParam()).toBe('mname=name&mtype=type');
      });

      it('ignores undefined filter', async () => {
        await client.fetchMetric('name', 'type', {
          filters: { dateRange: undefined },
        });
        expect(getQueryParam()).toBe('mname=name&mtype=type');
      });

      describe('group by filter', () => {
        it('handle group by func', async () => {
          await client.fetchMetric('name', 'type', {
            filters: { groupBy: { func: 'sum' } },
          });
          expect(getQueryParam()).toContain(`groupby_fn=sum`);
        });

        it('handle group by attribute', async () => {
          await client.fetchMetric('name', 'type', {
            filters: { groupBy: { attributes: ['attr_1'] } },
          });
          expect(getQueryParam()).toContain(`groupby_attrs=attr_1`);
        });

        it('handle group by multiple attributes', async () => {
          await client.fetchMetric('name', 'type', {
            filters: { groupBy: { attributes: ['attr_1', 'attr_2'] } },
          });
          expect(getQueryParam()).toContain(`groupby_attrs=attr_1,attr_2`);
        });
        it('ignores empty filter', async () => {
          await client.fetchMetric('name', 'type', {
            filters: { groupBy: {} },
          });
          expect(getQueryParam()).toBe('mname=name&mtype=type');
        });

        it('ignores empty list', async () => {
          await client.fetchMetric('name', 'type', {
            filters: { groupBy: { attributes: [] } },
          });
          expect(getQueryParam()).toBe('mname=name&mtype=type');
        });

        it('ignores undefined filter', async () => {
          await client.fetchMetric('name', 'type', {
            filters: { groupBy: undefined },
          });
          expect(getQueryParam()).toBe('mname=name&mtype=type');
        });
      });
    });

    it('rejects if results is missing from the response', async () => {
      axiosMock.onGet(metricsSearchUrl).reply(HTTP_STATUS_OK, {});
      const e = 'metrics are missing/invalid in the response';

      await expect(client.fetchMetric('name', 'type')).rejects.toThrow(e);
      expectErrorToBeReported(new Error(e));
    });

    it('rejects if metric name is missing', async () => {
      const e = 'fetchMetric() - metric name is required.';
      await expect(client.fetchMetric()).rejects.toThrow(e);
      expectErrorToBeReported(new Error(e));
    });

    it('rejects if metric type is missing', async () => {
      const e = 'fetchMetric() - metric type is required.';
      await expect(client.fetchMetric('name')).rejects.toThrow(e);
      expectErrorToBeReported(new Error(e));
    });
  });

  describe('fetchMetricSearchMetadata', () => {
    it('fetches the metric metadata from the API', async () => {
      const data = {
        name: 'system.network.packets',
        type: 'sum',
        description: 'System network packets',
        attribute_keys: ['device', 'direction'],
        last_ingested_at: 1706338215873651200,
        supported_aggregations: ['1m', '1h', '1d'],
        supported_functions: ['avg', 'sum', 'min', 'max', 'count'],
        default_group_by_attributes: ['*'],
        default_group_by_function: 'sum',
      };

      axiosMock.onGet(metricsSearchMetadataUrl).reply(HTTP_STATUS_OK, data);

      const result = await client.fetchMetricSearchMetadata('name', 'type');

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(metricsSearchMetadataUrl, {
        withCredentials: true,
        params: new URLSearchParams({ mname: 'name', mtype: 'type' }),
      });
      expect(result).toEqual(data);
    });
  });

  describe('fetchLogs', () => {
    const mockResponse = {
      results: [
        {
          timestamp: '2024-01-28T10:36:08.2960655Z',
          trace_id: 'trace-id',
          span_id: 'span-id',
          trace_flags: 1,
          severity_text: 'Information',
          severity_number: 1,
          service_name: 'a/service/name',
          body: 'GetCartAsync called with userId={userId} ',
          resource_attributes: {
            'container.id': '8aae63236c224245383acd38611a4e32d09b7630573421fcc801918eda378bf5',
            'k8s.deployment.name': 'otel-demo-cartservice',
            'k8s.namespace.name': 'otel-demo-app',
          },
          log_attributes: {
            userId: '',
          },
        },
      ],
      next_page_token: 'test-token',
    };
    const FETCHING_LOGS_ERROR = 'logs are missing/invalid in the response';

    beforeEach(() => {
      axiosMock.onGet(logsSearchUrl).reply(HTTP_STATUS_OK, mockResponse);
    });

    it('fetches logs from the logs URL', async () => {
      const result = await client.fetchLogs();

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(logsSearchUrl, {
        withCredentials: true,
        params: expect.any(URLSearchParams),
      });
      expect(result).toEqual({
        logs: mockResponse.results,
        nextPageToken: mockResponse.next_page_token,
      });
    });

    it('appends page_token if specified', async () => {
      await client.fetchLogs({ pageToken: 'page-token' });

      expect(getQueryParam()).toContain('page_token=page-token');
    });

    it('appends page_size if specified', async () => {
      await client.fetchLogs({ pageSize: 10 });

      expect(getQueryParam()).toContain('page_size=10');
    });

    it('rejects if logs are missing', async () => {
      axiosMock.onGet(logsSearchUrl).reply(HTTP_STATUS_OK, {});

      await expect(client.fetchLogs()).rejects.toThrow(FETCHING_LOGS_ERROR);
      expectErrorToBeReported(new Error(FETCHING_LOGS_ERROR));
    });

    it('rejects if logs are invalid', async () => {
      axiosMock.onGet(logsSearchUrl).reply(HTTP_STATUS_OK, { results: 'invalid' });

      await expect(client.fetchLogs()).rejects.toThrow(FETCHING_LOGS_ERROR);
      expectErrorToBeReported(new Error(FETCHING_LOGS_ERROR));
    });

    it('passes the abort controller to axios', async () => {
      const abortController = new AbortController();
      await client.fetchLogs({ abortController });

      expect(axios.get).toHaveBeenCalledWith(logsSearchUrl, {
        withCredentials: true,
        params: expect.any(URLSearchParams),
        signal: abortController.signal,
      });
    });

    describe('filters', () => {
      describe('date range filter', () => {
        it('handle predefined date range value', async () => {
          await client.fetchLogs({
            filters: { dateRange: { value: '5m' } },
          });
          expect(getQueryParam()).toContain(`period=5m`);
        });

        it('handle custom date range value', async () => {
          await client.fetchLogs({
            filters: {
              dateRange: {
                endDate: new Date('2020-07-06'),
                startDate: new Date('2020-07-05'),
                value: 'custom',
              },
            },
          });
          expect(getQueryParam()).toContain(
            'start_time=2020-07-05T00:00:00.000Z&end_time=2020-07-06T00:00:00.000Z',
          );
        });

        it('handles exact timestamps', async () => {
          await client.fetchLogs({
            filters: {
              dateRange: {
                timestamp: '2024-02-19T16:10:15.4433398Z',
                endDate: new Date('2024-02-19'),
                startDate: new Date('2024-02-19'),
                value: 'custom',
              },
            },
          });
          expect(getQueryParam()).toContain(
            'start_time=2024-02-19T16:10:15.4433398Z&end_time=2024-02-19T16:10:15.4433398Z',
          );
        });
      });

      describe('attributes filters', () => {
        it('converts filter to proper query params', async () => {
          await client.fetchLogs({
            filters: {
              attributes: {
                service: [
                  { operator: '=', value: 'serviceName' },
                  { operator: '!=', value: 'serviceName2' },
                ],
                severityName: [
                  { operator: '=', value: 'info' },
                  { operator: '!=', value: 'warning' },
                ],
                severityNumber: [
                  { operator: '=', value: '9' },
                  { operator: '!=', value: '10' },
                ],
                traceId: [{ operator: '=', value: 'traceId' }],
                spanId: [{ operator: '=', value: 'spanId' }],
                fingerprint: [{ operator: '=', value: 'fingerprint' }],
                traceFlags: [
                  { operator: '=', value: '1' },
                  { operator: '!=', value: '2' },
                ],
                attribute: [{ operator: '=', value: 'attr=bar' }],
                resourceAttribute: [{ operator: '=', value: 'res=foo' }],
                search: [{ value: 'some-search' }],
              },
            },
          });
          expect(getQueryParam()).toEqual(
            `service_name=serviceName&not[service_name]=serviceName2` +
              `&severity_name=info&not[severity_name]=warning` +
              `&severity_number=9&not[severity_number]=10` +
              `&trace_id=traceId` +
              `&span_id=spanId` +
              `&fingerprint=fingerprint` +
              `&trace_flags=1&not[trace_flags]=2` +
              `&log_attr_name=attr&log_attr_value=bar` +
              `&res_attr_name=res&res_attr_value=foo` +
              `&body=some-search`,
          );
        });

        it('ignores unsupported operators', async () => {
          await client.fetchLogs({
            filters: {
              attributes: {
                traceId: [{ operator: '!=', value: 'traceId2' }],
                spanId: [{ operator: '!=', value: 'spanId2' }],
                fingerprint: [{ operator: '!=', value: 'fingerprint2' }],
                attribute: [{ operator: '!=', value: 'bar' }],
                resourceAttribute: [{ operator: '!=', value: 'resourceAttribute2' }],
                unsupported: [{ value: 'something', operator: '=' }],
              },
            },
          });
          expect(getQueryParam()).toEqual('');
        });
      });

      it('ignores empty filter', async () => {
        await client.fetchLogs({
          filters: { attributes: {}, dateRange: {} },
        });
        expect(getQueryParam()).toBe('');
      });

      it('ignores undefined filter', async () => {
        await client.fetchLogs({
          filters: { dateRange: undefined, attributes: undefined },
        });
        expect(getQueryParam()).toBe('');
      });
    });
  });

  describe('fetchLogsSearchMetadata', () => {
    const mockResponse = {
      start_ts: 1713513680617331200,
      end_ts: 1714723280617331200,
      summary: {
        service_names: ['adservice', 'cartservice', 'quoteservice', 'recommendationservice'],
        trace_flags: [0, 1],
        severity_names: ['info', 'warn'],
        severity_numbers: [9, 13],
      },
      severity_numbers_counts: [
        {
          time: 1713519360000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
        {
          time: 1713545280000000000,
          counts: {
            13: 0,
            9: 0,
          },
        },
      ],
    };

    beforeEach(() => {
      axiosMock.onGet(logsSearchMetadataUrl).reply(HTTP_STATUS_OK, mockResponse);
    });

    it('fetches logs metadata from the logs URL', async () => {
      const result = await client.fetchLogsSearchMetadata();

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(logsSearchMetadataUrl, {
        withCredentials: true,
        params: expect.any(URLSearchParams),
      });
      expect(result).toEqual(mockResponse);
    });

    it('passes the abort controller to axios', async () => {
      const abortController = new AbortController();
      await client.fetchLogsSearchMetadata({ abortController });

      expect(axios.get).toHaveBeenCalledWith(logsSearchMetadataUrl, {
        withCredentials: true,
        params: expect.any(URLSearchParams),
        signal: abortController.signal,
      });
    });

    describe('filters', () => {
      describe('date range filter', () => {
        it('handle predefined date range value', async () => {
          await client.fetchLogsSearchMetadata({
            filters: { dateRange: { value: '5m' } },
          });
          expect(getQueryParam()).toContain(`period=5m`);
        });

        it('handle custom date range value', async () => {
          await client.fetchLogsSearchMetadata({
            filters: {
              dateRange: {
                endDate: new Date('2020-07-06'),
                startDate: new Date('2020-07-05'),
                value: 'custom',
              },
            },
          });
          expect(getQueryParam()).toContain(
            'start_time=2020-07-05T00:00:00.000Z&end_time=2020-07-06T00:00:00.000Z',
          );
        });

        it('handles exact timestamps', async () => {
          await client.fetchLogsSearchMetadata({
            filters: {
              dateRange: {
                timestamp: '2024-02-19T16:10:15.4433398Z',
                endDate: new Date('2024-02-19'),
                startDate: new Date('2024-02-19'),
                value: 'custom',
              },
            },
          });
          expect(getQueryParam()).toContain(
            'start_time=2024-02-19T16:10:15.4433398Z&end_time=2024-02-19T16:10:15.4433398Z',
          );
        });
      });

      describe('attributes filters', () => {
        it('converts filter to proper query params', async () => {
          await client.fetchLogsSearchMetadata({
            filters: {
              attributes: {
                service: [
                  { operator: '=', value: 'serviceName' },
                  { operator: '!=', value: 'serviceName2' },
                ],
                severityName: [
                  { operator: '=', value: 'info' },
                  { operator: '!=', value: 'warning' },
                ],
                severityNumber: [
                  { operator: '=', value: '9' },
                  { operator: '!=', value: '10' },
                ],
                traceId: [{ operator: '=', value: 'traceId' }],
                spanId: [{ operator: '=', value: 'spanId' }],
                fingerprint: [{ operator: '=', value: 'fingerprint' }],
                traceFlags: [
                  { operator: '=', value: '1' },
                  { operator: '!=', value: '2' },
                ],
                attribute: [{ operator: '=', value: 'attr=bar' }],
                resourceAttribute: [{ operator: '=', value: 'res=foo' }],
                search: [{ value: 'some-search' }],
              },
            },
          });
          expect(getQueryParam()).toEqual(
            `service_name=serviceName&not[service_name]=serviceName2` +
              `&severity_name=info&not[severity_name]=warning` +
              `&severity_number=9&not[severity_number]=10` +
              `&trace_id=traceId` +
              `&span_id=spanId` +
              `&fingerprint=fingerprint` +
              `&trace_flags=1&not[trace_flags]=2` +
              `&log_attr_name=attr&log_attr_value=bar` +
              `&res_attr_name=res&res_attr_value=foo` +
              `&body=some-search`,
          );
        });

        it('ignores unsupported operators', async () => {
          await client.fetchLogsSearchMetadata({
            filters: {
              attributes: {
                traceId: [{ operator: '!=', value: 'traceId2' }],
                spanId: [{ operator: '!=', value: 'spanId2' }],
                fingerprint: [{ operator: '!=', value: 'fingerprint2' }],
                attribute: [{ operator: '!=', value: 'bar' }],
                resourceAttribute: [{ operator: '!=', value: 'resourceAttribute2' }],
                unsupported: [{ value: 'something', operator: '=' }],
              },
            },
          });
          expect(getQueryParam()).toEqual('');
        });
      });

      it('ignores empty filter', async () => {
        await client.fetchLogsSearchMetadata({
          filters: { attributes: {}, dateRange: {} },
        });
        expect(getQueryParam()).toBe('');
      });

      it('ignores undefined filter', async () => {
        await client.fetchLogsSearchMetadata({
          filters: { dateRange: undefined, attributes: undefined },
        });
        expect(getQueryParam()).toBe('');
      });
    });
  });

  describe('fetchUsageData', () => {
    const mockResponse = {
      events: {
        6: {
          start_ts: 1717200000000000000,
          end_ts: 1719705600000000000,
          aggregated_total: 132,
          aggregated_per_feature: {
            metrics: 50,
            logs: 32,
            tracing: 50,
          },
          data: {
            metrics: [[1719446400000000000, 100]],
          },
          data_breakdown: 'daily',
          data_unit: '',
        },
      },
      storage: {
        6: {
          start_ts: 1717200000000000000,
          end_ts: 1719705600000000000,
          aggregated_total: 58476,
          aggregated_per_feature: {
            metrics: 15000,
            logs: 15000,
            tracing: 28476,
          },
          data: {
            metrics: [[1719446400000000000, 58476]],
          },
          data_breakdown: 'daily',
          data_unit: 'bytes',
        },
      },
    };
    beforeEach(() => {
      axiosMock.onGet(analyticsUrl).reply(HTTP_STATUS_OK, mockResponse);
    });

    it('fetches analytics data from URL', async () => {
      const result = await client.fetchUsageData();

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(analyticsUrl, {
        withCredentials: true,
        params: expect.any(URLSearchParams),
      });
      expect(result).toEqual(mockResponse);
    });

    it('adds a month query param if specified', async () => {
      await client.fetchUsageData({ period: { month: '06' } });

      expect(getQueryParam()).toBe('month=06');
    });

    it('adds a year query param if specified', async () => {
      await client.fetchUsageData({ period: { year: '2024' } });

      expect(getQueryParam()).toBe('year=2024');
    });

    it('ignores empty period param', async () => {
      await client.fetchUsageData({ period: {} });

      expect(getQueryParam()).toBe('');
    });
  });
});
