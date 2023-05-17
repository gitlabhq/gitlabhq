import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import setupAxiosStartupCalls from '~/lib/utils/axios_startup_calls';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('setupAxiosStartupCalls', () => {
  const AXIOS_RESPONSE = { text: 'AXIOS_RESPONSE' };
  const STARTUP_JS_RESPONSE = { text: 'STARTUP_JS_RESPONSE' };
  let mock;

  function mockFetchCall(status) {
    const p = {
      ok: status >= 200 && status < 300,
      status,
      headers: new Headers({ 'Content-Type': 'application/json' }),
      statusText: `MOCK-FETCH ${status}`,
      clone: () => p,
      json: () => Promise.resolve(STARTUP_JS_RESPONSE),
    };
    return Promise.resolve(p);
  }

  function mockConsoleWarn() {
    jest.spyOn(console, 'warn').mockImplementation();
  }

  function expectConsoleWarn(path) {
    // eslint-disable-next-line no-console
    expect(console.warn).toHaveBeenCalledWith(expect.stringMatching(path), expect.any(Error));
  }

  beforeEach(() => {
    window.gl = {};
    mock = new MockAdapter(axios);
    mock.onGet('/non-startup').reply(HTTP_STATUS_OK, AXIOS_RESPONSE);
    mock.onGet('/startup').reply(HTTP_STATUS_OK, AXIOS_RESPONSE);
    mock.onGet('/startup-failing').reply(HTTP_STATUS_OK, AXIOS_RESPONSE);
  });

  afterEach(() => {
    delete window.gl;
    axios.interceptors.request.handlers = [];
    mock.restore();
  });

  it('if no startupCalls are registered: does not register a request interceptor', () => {
    setupAxiosStartupCalls(axios);

    expect(axios.interceptors.request.handlers.length).toBe(0);
  });

  describe('if startupCalls are registered', () => {
    beforeEach(() => {
      window.gl.startup_calls = {
        '/startup': {
          fetchCall: mockFetchCall(HTTP_STATUS_OK),
        },
        '/startup-failing': {
          fetchCall: mockFetchCall(HTTP_STATUS_BAD_REQUEST),
        },
      };
      setupAxiosStartupCalls(axios);
    });

    it('registers a request interceptor', () => {
      expect(axios.interceptors.request.handlers.length).toBe(1);
    });

    it('detaches the request interceptor if every startup call has been made', async () => {
      expect(axios.interceptors.request.handlers[0]).not.toBeNull();

      await axios.get('/startup');
      mockConsoleWarn();
      await axios.get('/startup-failing');

      // Axios sets the interceptor to null
      expect(axios.interceptors.request.handlers[0]).toBeNull();
    });

    it('delegates to startup calls if URL is registered and call is successful', async () => {
      const { headers, data, status, statusText } = await axios.get('/startup');

      expect(headers).toEqual({ 'content-type': 'application/json' });
      expect(status).toBe(HTTP_STATUS_OK);
      expect(statusText).toBe('MOCK-FETCH 200');
      expect(data).toEqual(STARTUP_JS_RESPONSE);
      expect(data).not.toEqual(AXIOS_RESPONSE);
    });

    it('delegates to startup calls exactly once', async () => {
      await axios.get('/startup');
      const { data } = await axios.get('/startup');

      expect(data).not.toEqual(STARTUP_JS_RESPONSE);
      expect(data).toEqual(AXIOS_RESPONSE);
    });

    it('does not delegate to startup calls if the call is failing', async () => {
      mockConsoleWarn();
      const { data } = await axios.get('/startup-failing');

      expect(data).not.toEqual(STARTUP_JS_RESPONSE);
      expect(data).toEqual(AXIOS_RESPONSE);
      expectConsoleWarn('/startup-failing');
    });

    it('does not delegate to startup call if URL is not registered', async () => {
      const { data } = await axios.get('/non-startup');

      expect(data).toEqual(AXIOS_RESPONSE);
      expect(data).not.toEqual(STARTUP_JS_RESPONSE);
    });
  });

  describe('startup call', () => {
    beforeEach(() => {
      window.gon = { gitlab_url: 'https://example.org/gitlab' };
    });

    it('removes GitLab Base URL from startup call', async () => {
      window.gl.startup_calls = {
        '/startup': {
          fetchCall: mockFetchCall(HTTP_STATUS_OK),
        },
      };
      setupAxiosStartupCalls(axios);

      const { data } = await axios.get('https://example.org/gitlab/startup');

      expect(data).toEqual(STARTUP_JS_RESPONSE);
    });

    it('sorts the params in the requested API url', async () => {
      window.gl.startup_calls = {
        '/startup?alpha=true&bravo=true': {
          fetchCall: mockFetchCall(HTTP_STATUS_OK),
        },
      };
      setupAxiosStartupCalls(axios);

      // Use a full url instead of passing options = { params: { ... } } to axios.get
      // to ensure the params are listed in the specified order.
      const { data } = await axios.get('https://example.org/gitlab/startup?bravo=true&alpha=true');

      expect(data).toEqual(STARTUP_JS_RESPONSE);
    });
  });
});
