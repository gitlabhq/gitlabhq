import MockAdapter from 'axios-mock-adapter';
import * as Sentry from '@sentry/browser';
import { buildClient } from '~/observability/client';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/lib/utils/axios_utils');
jest.mock('@sentry/browser');

describe('buildClient', () => {
  let client;
  let axiosMock;

  const tracingUrl = 'https://example.com/tracing';
  const provisioningUrl = 'https://example.com/provisioning';

  const FETCHING_TRACES_ERROR = 'traces are missing/invalid in the response';

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    jest.spyOn(axios, 'get');

    client = buildClient({
      tracingUrl,
      provisioningUrl,
    });
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('isTracingEnabled', () => {
    it('returns true if requests succeedes', async () => {
      axiosMock.onGet(provisioningUrl).reply(200, {
        status: 'ready',
      });

      const enabled = await client.isTracingEnabled();

      expect(enabled).toBe(true);
    });

    it('returns false if response is 404', async () => {
      axiosMock.onGet(provisioningUrl).reply(404);

      const enabled = await client.isTracingEnabled();

      expect(enabled).toBe(false);
    });

    // we currently ignore the 'status' payload and just check if the request was successful
    // We might improve this as part of https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2315
    it('returns true for any status', async () => {
      axiosMock.onGet(provisioningUrl).reply(200, {
        status: 'not ready',
      });

      const enabled = await client.isTracingEnabled();

      expect(enabled).toBe(true);
    });

    it('throws in case of any non-404 error', async () => {
      axiosMock.onGet(provisioningUrl).reply(500);

      const e = 'Request failed with status code 500';
      await expect(client.isTracingEnabled()).rejects.toThrow(e);
      expect(Sentry.captureException).toHaveBeenCalledWith(new Error(e));
    });

    it('throws in case of unexpected response', async () => {
      axiosMock.onGet(provisioningUrl).reply(200, {});

      const e = 'Failed to check provisioning';
      await expect(client.isTracingEnabled()).rejects.toThrow(e);
      expect(Sentry.captureException).toHaveBeenCalledWith(new Error(e));
    });
  });

  describe('enableTraces', () => {
    it('makes a PUT request to the provisioning URL', async () => {
      let putConfig;
      axiosMock.onPut(provisioningUrl).reply((config) => {
        putConfig = config;
        return [200];
      });

      await client.enableTraces();

      expect(putConfig.withCredentials).toBe(true);
    });

    it('reports an error if the req fails', async () => {
      axiosMock.onPut(provisioningUrl).reply(401);

      const e = 'Request failed with status code 401';

      await expect(client.enableTraces()).rejects.toThrow(e);
      expect(Sentry.captureException).toHaveBeenCalledWith(new Error(e));
    });
  });

  describe('fetchTrace', () => {
    it('fetches the trace from the tracing URL', async () => {
      const mockTraces = [
        {
          trace_id: 'trace-1',
          duration_nano: 3000,
          spans: [{ duration_nano: 1000 }, { duration_nano: 2000 }],
        },
      ];

      axiosMock.onGet(tracingUrl).reply(200, {
        traces: mockTraces,
      });

      const result = await client.fetchTrace('trace-1');

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(tracingUrl, {
        withCredentials: true,
        params: { trace_id: 'trace-1' },
      });
      expect(result).toEqual(mockTraces[0]);
    });

    it('rejects if trace id is missing', () => {
      return expect(client.fetchTrace()).rejects.toThrow('traceId is required.');
    });

    it('rejects if traces are empty', async () => {
      axiosMock.onGet(tracingUrl).reply(200, { traces: [] });

      await expect(client.fetchTrace('trace-1')).rejects.toThrow(FETCHING_TRACES_ERROR);
      expect(Sentry.captureException).toHaveBeenCalledWith(new Error(FETCHING_TRACES_ERROR));
    });

    it('rejects if traces are invalid', async () => {
      axiosMock.onGet(tracingUrl).reply(200, { traces: 'invalid' });

      await expect(client.fetchTraces()).rejects.toThrow(FETCHING_TRACES_ERROR);
      expect(Sentry.captureException).toHaveBeenCalledWith(new Error(FETCHING_TRACES_ERROR));
    });
  });

  describe('fetchTraces', () => {
    it('fetches traces from the tracing URL', async () => {
      const mockTraces = [
        {
          trace_id: 'trace-1',
          duration_nano: 3000,
          spans: [{ duration_nano: 1000 }, { duration_nano: 2000 }],
        },
        { trace_id: 'trace-2', duration_nano: 3000, spans: [{ duration_nano: 2000 }] },
      ];

      axiosMock.onGet(tracingUrl).reply(200, {
        traces: mockTraces,
      });

      const result = await client.fetchTraces();

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(tracingUrl, {
        withCredentials: true,
        params: new URLSearchParams(),
      });
      expect(result).toEqual(mockTraces);
    });

    it('rejects if traces are missing', async () => {
      axiosMock.onGet(tracingUrl).reply(200, {});

      await expect(client.fetchTraces()).rejects.toThrow(FETCHING_TRACES_ERROR);
      expect(Sentry.captureException).toHaveBeenCalledWith(new Error(FETCHING_TRACES_ERROR));
    });

    it('rejects if traces are invalid', async () => {
      axiosMock.onGet(tracingUrl).reply(200, { traces: 'invalid' });

      await expect(client.fetchTraces()).rejects.toThrow(FETCHING_TRACES_ERROR);
      expect(Sentry.captureException).toHaveBeenCalledWith(new Error(FETCHING_TRACES_ERROR));
    });

    describe('query filter', () => {
      beforeEach(() => {
        axiosMock.onGet(tracingUrl).reply(200, {
          traces: [],
        });
      });

      const getQueryParam = () => decodeURIComponent(axios.get.mock.calls[0][1].params.toString());

      it('does not set any query param without filters', async () => {
        await client.fetchTraces();

        expect(getQueryParam()).toBe('');
      });

      it('converts filter to proper query params', async () => {
        await client.fetchTraces({
          durationMs: [
            { operator: '>', value: '100' },
            { operator: '<', value: '1000' },
          ],
          operation: [
            { operator: '=', value: 'op' },
            { operator: '!=', value: 'not-op' },
          ],
          serviceName: [
            { operator: '=', value: 'service' },
            { operator: '!=', value: 'not-service' },
          ],
          period: [{ operator: '=', value: '5m' }],
          traceId: [
            { operator: '=', value: 'trace-id' },
            { operator: '!=', value: 'not-trace-id' },
          ],
        });
        expect(getQueryParam()).toBe(
          'gt[duration_nano]=100000&lt[duration_nano]=1000000' +
            '&operation=op&not[operation]=not-op' +
            '&service_name=service&not[service_name]=not-service' +
            '&period=5m' +
            '&trace_id=trace-id&not[trace_id]=not-trace-id',
        );
      });

      it('handles repeated params', async () => {
        await client.fetchTraces({
          operation: [
            { operator: '=', value: 'op' },
            { operator: '=', value: 'op2' },
          ],
        });
        expect(getQueryParam()).toBe('operation=op&operation=op2');
      });

      it('ignores unsupported filters', async () => {
        await client.fetchTraces({
          unsupportedFilter: [{ operator: '=', value: 'foo' }],
        });

        expect(getQueryParam()).toBe('');
      });

      it('ignores empty filters', async () => {
        await client.fetchTraces({
          durationMs: null,
          traceId: undefined,
        });

        expect(getQueryParam()).toBe('');
      });

      it('ignores unsupported operators', async () => {
        await client.fetchTraces({
          durationMs: [
            { operator: '*', value: 'foo' },
            { operator: '=', value: 'foo' },
            { operator: '!=', value: 'foo' },
          ],
          operation: [
            { operator: '>', value: 'foo' },
            { operator: '<', value: 'foo' },
          ],
          serviceName: [
            { operator: '>', value: 'foo' },
            { operator: '<', value: 'foo' },
          ],
          period: [{ operator: '!=', value: 'foo' }],
          traceId: [
            { operator: '>', value: 'foo' },
            { operator: '<', value: 'foo' },
          ],
        });

        expect(getQueryParam()).toBe('');
      });
    });
  });
});
