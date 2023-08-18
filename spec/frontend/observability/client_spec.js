import MockAdapter from 'axios-mock-adapter';
import { buildClient } from '~/observability/client';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/lib/utils/axios_utils');

describe('buildClient', () => {
  let client;
  let axiosMock;

  const tracingUrl = 'https://example.com/tracing';
  const EXPECTED_ERROR_MESSAGE = 'traces are missing/invalid in the response';

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    jest.spyOn(axios, 'get');

    client = buildClient({
      tracingUrl,
      provisioningUrl: 'https://example.com/provisioning',
    });
  });

  afterEach(() => {
    axiosMock.restore();
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

    it('rejects if traces are empty', () => {
      axiosMock.onGet(tracingUrl).reply(200, { traces: [] });

      return expect(client.fetchTrace('trace-1')).rejects.toThrow(EXPECTED_ERROR_MESSAGE);
    });

    it('rejects if traces are invalid', () => {
      axiosMock.onGet(tracingUrl).reply(200, { traces: 'invalid' });

      return expect(client.fetchTraces()).rejects.toThrow(EXPECTED_ERROR_MESSAGE);
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

    it('rejects if traces are missing', () => {
      axiosMock.onGet(tracingUrl).reply(200, {});

      return expect(client.fetchTraces()).rejects.toThrow(EXPECTED_ERROR_MESSAGE);
    });

    it('rejects if traces are invalid', () => {
      axiosMock.onGet(tracingUrl).reply(200, { traces: 'invalid' });

      return expect(client.fetchTraces()).rejects.toThrow(EXPECTED_ERROR_MESSAGE);
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
