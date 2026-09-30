import { createEtagFetch } from '~/lib/apollo/etag_fetch';

const URL = '/api/graphql';
const BODY = JSON.stringify({ operationName: 'getPipelines', variables: { first: 15 } });
const DATA = JSON.stringify({ data: { project: { id: '1' } } });

const mockResponse = ({ status = 200, etag, contentType, body = '' } = {}) => {
  const headers = new Headers({
    ...(etag && { ETag: etag }),
    ...(contentType && { 'Content-Type': contentType }),
  });
  return {
    status,
    ok: status >= 200 && status < 300,
    headers,
    clone: () => ({ text: () => Promise.resolve(body) }),
  };
};

const etagOptions = (body = BODY) => ({
  method: 'POST',
  body,
  headers: { 'x-gitlab-graphql-resource-etag': '/api/graphql:project_pipelines/1' },
});

describe('createEtagFetch', () => {
  let fetchFn;
  let etagFetch;

  // jsdom does not provide the Fetch API `Response`, which the 304 replay constructs.
  beforeAll(() => {
    global.Response = class {
      constructor(body, { status, headers }) {
        this.status = status;
        this.headers = headers;
        this.text = () => Promise.resolve(body);
      }
    };
  });

  afterAll(() => {
    delete global.Response;
  });

  beforeEach(() => {
    fetchFn = jest.fn();
    etagFetch = createEtagFetch(fetchFn);
  });

  describe('when the request has no eTag resource header', () => {
    it('passes the request through unchanged', async () => {
      const response = mockResponse({ etag: 'W/"1"' });
      const options = { method: 'POST', body: BODY, headers: {} };
      fetchFn.mockResolvedValue(response);

      expect(await etagFetch(URL, options)).toBe(response);
      expect(fetchFn).toHaveBeenCalledWith(URL, options);
    });
  });

  describe('when the request has an eTag resource header', () => {
    it('does not send If-None-Match on the first request', async () => {
      fetchFn.mockResolvedValue(mockResponse({ etag: 'W/"1"', body: DATA }));

      await etagFetch(URL, etagOptions());

      expect(fetchFn.mock.calls[0][1].headers['If-None-Match']).toBeUndefined();
    });

    describe('after a response with an eTag', () => {
      beforeEach(async () => {
        fetchFn.mockResolvedValueOnce(
          mockResponse({ etag: 'W/"1"', contentType: 'application/json', body: DATA }),
        );
        await etagFetch(URL, etagOptions());
      });

      it('sends If-None-Match on the next identical request', async () => {
        fetchFn.mockResolvedValueOnce(mockResponse({ status: 304 }));

        await etagFetch(URL, etagOptions());

        expect(fetchFn.mock.calls[1][1].headers['If-None-Match']).toBe('W/"1"');
      });

      it('replays the stored body as a 200 on a 304', async () => {
        fetchFn.mockResolvedValueOnce(mockResponse({ status: 304 }));

        const response = await etagFetch(URL, etagOptions());

        expect(response.status).toBe(200);
        expect(await response.text()).toBe(DATA);
      });

      it('restores the stored content type on the replayed response', async () => {
        fetchFn.mockResolvedValueOnce(mockResponse({ status: 304 }));

        const response = await etagFetch(URL, etagOptions());

        expect(response.headers.get('content-type')).toBe('application/json');
      });

      it('does not send If-None-Match when the variables differ', async () => {
        fetchFn.mockResolvedValueOnce(mockResponse({ etag: 'W/"1"', body: DATA }));

        await etagFetch(URL, etagOptions(JSON.stringify({ variables: { first: 30 } })));

        expect(fetchFn.mock.calls[1][1].headers['If-None-Match']).toBeUndefined();
      });
    });
  });
});
