import MockAdapter from 'axios-mock-adapter';
import { buildClient } from '~/observability/client';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/lib/utils/axios_utils');

describe('buildClient', () => {
  let client;
  let axiosMock;

  const tracingUrl = 'https://example.com/tracing';

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

  describe('fetchTraces', () => {
    it('should fetch traces from the tracing URL', async () => {
      const mockTraces = [
        { id: 1, spans: [{ duration_nano: 1000 }, { duration_nano: 2000 }] },
        { id: 2, spans: [{ duration_nano: 2000 }] },
      ];

      axiosMock.onGet(tracingUrl).reply(200, {
        traces: mockTraces,
      });

      const result = await client.fetchTraces();

      expect(axios.get).toHaveBeenCalledTimes(1);
      expect(axios.get).toHaveBeenCalledWith(tracingUrl, {
        withCredentials: true,
      });
      expect(result).toEqual([
        { id: 1, spans: [{ duration_nano: 1000 }, { duration_nano: 2000 }], duration: 3 },
        { id: 2, spans: [{ duration_nano: 2000 }], duration: 2 },
      ]);
    });

    it('rejects if traces are missing', () => {
      axiosMock.onGet(tracingUrl).reply(200, {});

      return expect(client.fetchTraces()).rejects.toThrow(
        'traces are missing/invalid in the response',
      );
    });

    it('rejects if traces are invalid', () => {
      axiosMock.onGet(tracingUrl).reply(200, { traces: 'invalid' });

      return expect(client.fetchTraces()).rejects.toThrow(
        'traces are missing/invalid in the response',
      );
    });
  });
});
