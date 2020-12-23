import { ApolloLink, Observable } from 'apollo-link';
import { StartupJSLink } from '~/lib/utils/apollo_startup_js_link';

describe('StartupJSLink', () => {
  const FORWARDED_RESPONSE = { data: 'FORWARDED_RESPONSE' };

  const STARTUP_JS_RESPONSE = { data: 'STARTUP_JS_RESPONSE' };
  const OPERATION_NAME = 'startupJSQuery';
  const STARTUP_JS_QUERY = `query ${OPERATION_NAME}($id: Int = 3){
    name
    id
  }`;

  const STARTUP_JS_RESPONSE_TWO = { data: 'STARTUP_JS_RESPONSE_TWO' };
  const OPERATION_NAME_TWO = 'startupJSQueryTwo';
  const STARTUP_JS_QUERY_TWO = `query ${OPERATION_NAME_TWO}($id: Int = 3){
    id
    name
  }`;

  const ERROR_RESPONSE = {
    data: {
      user: null,
    },
    errors: [
      {
        path: ['user'],
        locations: [{ line: 2, column: 3 }],
        extensions: {
          message: 'Object not found',
          type: 2,
        },
      },
    ],
  };

  let startupLink;
  let link;

  function mockFetchCall(status = 200, response = STARTUP_JS_RESPONSE) {
    const p = {
      ok: status >= 200 && status < 300,
      status,
      headers: new Headers({ 'Content-Type': 'application/json' }),
      statusText: `MOCK-FETCH ${status}`,
      clone: () => p,
      json: () => Promise.resolve(response),
    };
    return Promise.resolve(p);
  }

  function mockOperation({ operationName = OPERATION_NAME, variables = { id: 3 } } = {}) {
    return { operationName, variables, setContext: () => {} };
  }

  const setupLink = () => {
    startupLink = new StartupJSLink();
    link = ApolloLink.from([startupLink, new ApolloLink(() => Observable.of(FORWARDED_RESPONSE))]);
  };

  it('forwards requests if no calls are set up', (done) => {
    setupLink();
    link.request(mockOperation()).subscribe((result) => {
      expect(result).toEqual(FORWARDED_RESPONSE);
      expect(startupLink.startupCalls).toBe(null);
      expect(startupLink.request).toEqual(StartupJSLink.noopRequest);
      done();
    });
  });

  it('forwards requests if the operation is not pre-loaded', (done) => {
    window.gl = {
      startup_graphql_calls: [
        {
          fetchCall: mockFetchCall(),
          query: STARTUP_JS_QUERY,
          variables: { id: 3 },
        },
      ],
    };
    setupLink();
    link.request(mockOperation({ operationName: 'notLoaded' })).subscribe((result) => {
      expect(result).toEqual(FORWARDED_RESPONSE);
      expect(startupLink.startupCalls.size).toBe(1);
      done();
    });
  });

  describe('variable match errors: ', () => {
    it('forwards requests if the variables are not matching', (done) => {
      window.gl = {
        startup_graphql_calls: [
          {
            fetchCall: mockFetchCall(),
            query: STARTUP_JS_QUERY,
            variables: { id: 'NOT_MATCHING' },
          },
        ],
      };
      setupLink();
      link.request(mockOperation()).subscribe((result) => {
        expect(result).toEqual(FORWARDED_RESPONSE);
        expect(startupLink.startupCalls.size).toBe(0);
        done();
      });
    });

    it('forwards requests if more variables are set in the operation', (done) => {
      window.gl = {
        startup_graphql_calls: [
          {
            fetchCall: mockFetchCall(),
            query: STARTUP_JS_QUERY,
          },
        ],
      };
      setupLink();
      link.request(mockOperation()).subscribe((result) => {
        expect(result).toEqual(FORWARDED_RESPONSE);
        expect(startupLink.startupCalls.size).toBe(0);
        done();
      });
    });

    it('forwards requests if less variables are set in the operation', (done) => {
      window.gl = {
        startup_graphql_calls: [
          {
            fetchCall: mockFetchCall(),
            query: STARTUP_JS_QUERY,
            variables: { id: 3, name: 'tanuki' },
          },
        ],
      };
      setupLink();
      link.request(mockOperation({ variables: { id: 3 } })).subscribe((result) => {
        expect(result).toEqual(FORWARDED_RESPONSE);
        expect(startupLink.startupCalls.size).toBe(0);
        done();
      });
    });

    it('forwards requests if different variables are set', (done) => {
      window.gl = {
        startup_graphql_calls: [
          {
            fetchCall: mockFetchCall(),
            query: STARTUP_JS_QUERY,
            variables: { name: 'tanuki' },
          },
        ],
      };
      setupLink();
      link.request(mockOperation({ variables: { id: 3 } })).subscribe((result) => {
        expect(result).toEqual(FORWARDED_RESPONSE);
        expect(startupLink.startupCalls.size).toBe(0);
        done();
      });
    });

    it('forwards requests if array variables have a different order', (done) => {
      window.gl = {
        startup_graphql_calls: [
          {
            fetchCall: mockFetchCall(),
            query: STARTUP_JS_QUERY,
            variables: { id: [3, 4] },
          },
        ],
      };
      setupLink();
      link.request(mockOperation({ variables: { id: [4, 3] } })).subscribe((result) => {
        expect(result).toEqual(FORWARDED_RESPONSE);
        expect(startupLink.startupCalls.size).toBe(0);
        done();
      });
    });
  });

  describe('error handling', () => {
    it('forwards the call if the fetchCall is failing with a HTTP Error', (done) => {
      window.gl = {
        startup_graphql_calls: [
          {
            fetchCall: mockFetchCall(404),
            query: STARTUP_JS_QUERY,
            variables: { id: 3 },
          },
        ],
      };
      setupLink();
      link.request(mockOperation()).subscribe((result) => {
        expect(result).toEqual(FORWARDED_RESPONSE);
        expect(startupLink.startupCalls.size).toBe(0);
        done();
      });
    });

    it('forwards the call if it errors (e.g. failing JSON)', (done) => {
      window.gl = {
        startup_graphql_calls: [
          {
            fetchCall: Promise.reject(new Error('Parsing failed')),
            query: STARTUP_JS_QUERY,
            variables: { id: 3 },
          },
        ],
      };
      setupLink();
      link.request(mockOperation()).subscribe((result) => {
        expect(result).toEqual(FORWARDED_RESPONSE);
        expect(startupLink.startupCalls.size).toBe(0);
        done();
      });
    });

    it('forwards the call if the response contains an error', (done) => {
      window.gl = {
        startup_graphql_calls: [
          {
            fetchCall: mockFetchCall(200, ERROR_RESPONSE),
            query: STARTUP_JS_QUERY,
            variables: { id: 3 },
          },
        ],
      };
      setupLink();
      link.request(mockOperation()).subscribe((result) => {
        expect(result).toEqual(FORWARDED_RESPONSE);
        expect(startupLink.startupCalls.size).toBe(0);
        done();
      });
    });

    it("forwards the call if the response doesn't contain a data object", (done) => {
      window.gl = {
        startup_graphql_calls: [
          {
            fetchCall: mockFetchCall(200, { 'no-data': 'yay' }),
            query: STARTUP_JS_QUERY,
            variables: { id: 3 },
          },
        ],
      };
      setupLink();
      link.request(mockOperation()).subscribe((result) => {
        expect(result).toEqual(FORWARDED_RESPONSE);
        expect(startupLink.startupCalls.size).toBe(0);
        done();
      });
    });
  });

  it('resolves the request if the operation is matching', (done) => {
    window.gl = {
      startup_graphql_calls: [
        {
          fetchCall: mockFetchCall(),
          query: STARTUP_JS_QUERY,
          variables: { id: 3 },
        },
      ],
    };
    setupLink();
    link.request(mockOperation()).subscribe((result) => {
      expect(result).toEqual(STARTUP_JS_RESPONSE);
      expect(startupLink.startupCalls.size).toBe(0);
      done();
    });
  });

  it('resolves the request exactly once', (done) => {
    window.gl = {
      startup_graphql_calls: [
        {
          fetchCall: mockFetchCall(),
          query: STARTUP_JS_QUERY,
          variables: { id: 3 },
        },
      ],
    };
    setupLink();
    link.request(mockOperation()).subscribe((result) => {
      expect(result).toEqual(STARTUP_JS_RESPONSE);
      expect(startupLink.startupCalls.size).toBe(0);
      link.request(mockOperation()).subscribe((result2) => {
        expect(result2).toEqual(FORWARDED_RESPONSE);
        done();
      });
    });
  });

  it('resolves the request if the variables have a different order', (done) => {
    window.gl = {
      startup_graphql_calls: [
        {
          fetchCall: mockFetchCall(),
          query: STARTUP_JS_QUERY,
          variables: { id: 3, name: 'foo' },
        },
      ],
    };
    setupLink();
    link.request(mockOperation({ variables: { name: 'foo', id: 3 } })).subscribe((result) => {
      expect(result).toEqual(STARTUP_JS_RESPONSE);
      expect(startupLink.startupCalls.size).toBe(0);
      done();
    });
  });

  it('resolves the request if the variables have undefined values', (done) => {
    window.gl = {
      startup_graphql_calls: [
        {
          fetchCall: mockFetchCall(),
          query: STARTUP_JS_QUERY,
          variables: { name: 'foo' },
        },
      ],
    };
    setupLink();
    link
      .request(mockOperation({ variables: { name: 'foo', undef: undefined } }))
      .subscribe((result) => {
        expect(result).toEqual(STARTUP_JS_RESPONSE);
        expect(startupLink.startupCalls.size).toBe(0);
        done();
      });
  });

  it('resolves the request if the variables are of an array format', (done) => {
    window.gl = {
      startup_graphql_calls: [
        {
          fetchCall: mockFetchCall(),
          query: STARTUP_JS_QUERY,
          variables: { id: [3, 4] },
        },
      ],
    };
    setupLink();
    link.request(mockOperation({ variables: { id: [3, 4] } })).subscribe((result) => {
      expect(result).toEqual(STARTUP_JS_RESPONSE);
      expect(startupLink.startupCalls.size).toBe(0);
      done();
    });
  });

  it('resolves multiple requests correctly', (done) => {
    window.gl = {
      startup_graphql_calls: [
        {
          fetchCall: mockFetchCall(),
          query: STARTUP_JS_QUERY,
          variables: { id: 3 },
        },
        {
          fetchCall: mockFetchCall(200, STARTUP_JS_RESPONSE_TWO),
          query: STARTUP_JS_QUERY_TWO,
          variables: { id: 3 },
        },
      ],
    };
    setupLink();
    link.request(mockOperation({ operationName: OPERATION_NAME_TWO })).subscribe((result) => {
      expect(result).toEqual(STARTUP_JS_RESPONSE_TWO);
      expect(startupLink.startupCalls.size).toBe(1);
      link.request(mockOperation({ operationName: OPERATION_NAME })).subscribe((result2) => {
        expect(result2).toEqual(STARTUP_JS_RESPONSE);
        expect(startupLink.startupCalls.size).toBe(0);
        done();
      });
    });
  });
});
