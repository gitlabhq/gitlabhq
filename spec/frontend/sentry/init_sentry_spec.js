/* eslint-disable no-restricted-imports */
import { captureException, captureMessage, addBreadcrumb, SDK_VERSION } from '@sentry/browser';
import * as Sentry from '@sentry/browser';

import {
  initSentry,
  isExternalOriginError,
  isServerUnavailableError,
  isNonActionableError,
} from '~/sentry/init_sentry';

const mockDsn = 'https://123@sentry.gitlab.test/123';
const mockEnvironment = 'development';
const mockCurrentUserId = 1;
const mockGitlabUrl = 'https://gitlab.com';
const mockAssetHost = 'https://assets.gitlab-static.net';
const mockVersion = '1.0.0';
const mockRevision = '00112233';
const mockFeatureCategory = 'my_feature_category';
const mockPage = 'index:page';
const mockSentryClientsideTracesSampleRate = 0.1;

jest.mock('@sentry/browser', () => {
  return {
    ...jest.createMockFromModule('@sentry/browser'),

    // unmock actual configuration options
    browserSessionIntegration: jest.fn().mockReturnValue('mockBrowserSessionIntegration'),
    browserTracingIntegration: jest.fn().mockReturnValue('mockBrowserTracingIntegration'),
  };
});

describe('SentryConfig', () => {
  let mockScope;
  let mockSentryInit;

  beforeEach(() => {
    window.gon = {
      sentry_dsn: mockDsn,
      sentry_environment: mockEnvironment,
      current_user_id: mockCurrentUserId,
      gitlab_url: mockGitlabUrl,
      asset_host: mockAssetHost,
      version: mockVersion,
      revision: mockRevision,
      feature_category: mockFeatureCategory,
      sentry_clientside_traces_sample_rate: mockSentryClientsideTracesSampleRate,
    };

    document.body.dataset.page = mockPage;

    mockSentryInit = jest.spyOn(Sentry, 'init');
    mockScope = {
      setTags: jest.fn(),
      setUser: jest.fn(),
    };
  });

  afterEach(() => {
    // eslint-disable-next-line no-underscore-dangle
    window._Sentry = undefined;
  });

  describe('initSentry', () => {
    describe('when sentry is initialized', () => {
      beforeEach(() => {
        initSentry();
      });

      it('calls Sentry.init with gon values and configuration', () => {
        expect(mockSentryInit).toHaveBeenCalledWith(
          expect.objectContaining({
            dsn: mockDsn,
            release: mockRevision,
            allowUrls: [mockGitlabUrl, 'webpack-internal://'],
            environment: mockEnvironment,
            beforeSend: expect.any(Function),
            ignoreErrors: [
              /Network Error/i,
              /NetworkError/i,
              /Failed to fetch/i,
              /Load failed/i,
              /NavigationDuplicated/,
              /You must be logged in/,
              /Request failed with status code \d+/,
              /Response not successful: Received status code \d+/,
            ],
            tracePropagationTargets: [/^\//],
            tracesSampleRate: mockSentryClientsideTracesSampleRate,
            integrations: ['mockBrowserSessionIntegration', 'mockBrowserTracingIntegration'],
            initialScope: expect.any(Function),
          }),
        );
      });

      it('sets up integrations', () => {
        expect(Sentry.browserSessionIntegration).toHaveBeenCalled();
        expect(Sentry.browserTracingIntegration).toHaveBeenCalled();
      });

      it('Uses data-page to set browserTracingIntegration transaction name', () => {
        const mockBrowserTracingIntegration = jest.spyOn(Sentry, 'browserTracingIntegration');

        initSentry();

        const context = mockBrowserTracingIntegration.mock.calls[0][0].beforeStartSpan();

        expect(context).toMatchObject({ name: mockPage });
      });

      it('calls Sentry.setTags with gon values', () => {
        mockSentryInit.mock.calls[0][0].initialScope(mockScope);

        expect(mockScope.setTags).toHaveBeenCalledTimes(1);
        expect(mockScope.setTags).toHaveBeenCalledWith({
          page: mockPage,
          version: mockVersion,
          feature_category: mockFeatureCategory,
        });
      });

      it('calls Sentry.setUser with gon values', () => {
        mockSentryInit.mock.calls[0][0].initialScope(mockScope);

        expect(mockScope.setUser).toHaveBeenCalledTimes(1);
        expect(mockScope.setUser).toHaveBeenCalledWith({
          id: mockCurrentUserId,
        });
      });

      it('sets global sentry', () => {
        // eslint-disable-next-line no-underscore-dangle
        expect(window._Sentry).toEqual({
          captureException,
          captureMessage,
          addBreadcrumb,
          SDK_VERSION,
        });
      });

      describe('isExternalOriginError', () => {
        const buildEvent = (frames) => ({
          exception: {
            values: [
              {
                type: 'TypeError',
                value: 'Failed to fetch',
                stacktrace: { frames },
              },
            ],
          },
        });

        it('returns true when all frames are anonymous', () => {
          const event = buildEvent([
            { filename: '<anonymous>', in_app: true },
            { filename: '<anonymous>', in_app: true },
          ]);

          expect(isExternalOriginError(event)).toBe(true);
        });

        it('returns true when frames point to external domains', () => {
          const event = buildEvent([
            { filename: 'https://malicious-extension.com/script.js', in_app: true },
            { filename: '<anonymous>', in_app: true },
          ]);

          expect(isExternalOriginError(event)).toBe(true);
        });

        it('returns true for chrome-extension frames', () => {
          const event = buildEvent([
            { filename: 'chrome-extension://abc123/content.js', in_app: true },
          ]);

          expect(isExternalOriginError(event)).toBe(true);
        });

        it('returns true for any error type with external frames', () => {
          const event = {
            exception: {
              values: [
                {
                  type: 'ReferenceError',
                  value: 'x is not defined',
                  stacktrace: {
                    frames: [{ filename: '<anonymous>', in_app: true }],
                  },
                },
              ],
            },
          };

          expect(isExternalOriginError(event)).toBe(true);
        });

        it('returns true when frames have no filename', () => {
          const event = buildEvent([{ in_app: true }, { filename: '<anonymous>', in_app: true }]);

          expect(isExternalOriginError(event)).toBe(true);
        });

        it('returns false when a GitLab origin frame is present', () => {
          const event = buildEvent([
            { filename: '<anonymous>', in_app: true },
            { filename: `${mockGitlabUrl}/assets/webpack/app.abc123.chunk.js`, in_app: true },
          ]);

          expect(isExternalOriginError(event)).toBe(false);
        });

        it('returns false when a CDN asset host frame is present', () => {
          const event = buildEvent([
            { filename: '<anonymous>', in_app: true },
            {
              filename: `${mockAssetHost}/assets/webpack/pages.abc123.chunk.js`,
              in_app: true,
            },
          ]);

          expect(isExternalOriginError(event)).toBe(false);
        });

        it('returns false when mixed CDN and GitLab origin frames are present', () => {
          const event = buildEvent([
            {
              filename: `${mockAssetHost}/assets/webpack/runtime.abc123.js`,
              in_app: true,
            },
            { filename: `${mockGitlabUrl}/assets/webpack/app.abc123.chunk.js`, in_app: true },
          ]);

          expect(isExternalOriginError(event)).toBe(false);
        });

        it('returns true when asset_host is not set and frames are external', () => {
          window.gon.asset_host = undefined;
          const event = buildEvent([
            { filename: 'https://malicious-extension.com/script.js', in_app: true },
          ]);

          expect(isExternalOriginError(event)).toBe(true);
        });

        it('returns false when event has no exception', () => {
          expect(isExternalOriginError({})).toBe(false);
        });

        it('returns false when frames are empty', () => {
          const event = buildEvent([]);

          expect(isExternalOriginError(event)).toBe(false);
        });

        it('returns false when gon.gitlab_url is not set', () => {
          window.gon.gitlab_url = undefined;
          const event = buildEvent([{ filename: '<anonymous>', in_app: true }]);

          expect(isExternalOriginError(event)).toBe(false);
        });

        it('keeps GitLab errors even when mixed with external frames', () => {
          const event = buildEvent([
            { filename: 'https://third-party.com/tracker.js', in_app: true },
            { filename: `${mockGitlabUrl}/assets/webpack/pages.abc123.chunk.js`, in_app: true },
          ]);

          expect(isExternalOriginError(event)).toBe(false);
        });
      });
    });

    describe('beforeSend', () => {
      let beforeSend;

      beforeEach(() => {
        initSentry();
        beforeSend = mockSentryInit.mock.calls[0][0].beforeSend;
      });

      it('drops events caused by a 503 ServerError', () => {
        const error = new Error('Response not successful: Received status code 503');
        error.name = 'ServerError';
        error.statusCode = 503;

        expect(beforeSend({ event_id: '123' }, { originalException: error })).toBeNull();
      });

      it('drops non-503 server errors as non-actionable HTTP errors', () => {
        const error = new Error('Response not successful: Received status code 500');
        error.name = 'ServerError';
        error.statusCode = 500;

        expect(beforeSend({ event_id: '456' }, { originalException: error })).toBeNull();
      });

      it('keeps events for non-ServerError exceptions', () => {
        const error = new TypeError('Cannot read properties of undefined');
        const event = { event_id: '789' };

        expect(beforeSend(event, { originalException: error })).toBe(event);
      });

      it('keeps events when hint has no originalException', () => {
        const event = { event_id: 'abc' };

        expect(beforeSend(event, {})).toBe(event);
        expect(beforeSend(event, undefined)).toBe(event);
      });

      it('drops events sent via captureException with a non-actionable message', () => {
        const event = {
          event_id: 'def',
          exception: {
            values: [{ type: 'Error', value: 'Request failed with status code 422' }],
          },
        };

        expect(
          beforeSend(event, {
            originalException: new Error('Request failed with status code 422'),
          }),
        ).toBeNull();
      });
    });

    describe('when user is not logged in', () => {
      beforeEach(() => {
        window.gon.current_user_id = undefined;
        initSentry();
      });

      it('does not call Sentry.setUser', () => {
        mockSentryInit.mock.calls[0][0].initialScope(mockScope);

        expect(mockScope.setUser).not.toHaveBeenCalled();
      });
    });

    describe('when gon is not defined', () => {
      beforeEach(() => {
        window.gon = undefined;
        initSentry();
      });

      it('Sentry.init is not called', () => {
        expect(mockSentryInit).not.toHaveBeenCalled();

        // eslint-disable-next-line no-underscore-dangle
        expect(window._Sentry).toBe(undefined);
      });
    });

    describe('when dsn is not configured', () => {
      beforeEach(() => {
        window.gon.sentry_dsn = undefined;
        initSentry();
      });

      it('Sentry.init is not called', () => {
        expect(mockSentryInit).not.toHaveBeenCalled();

        // eslint-disable-next-line no-underscore-dangle
        expect(window._Sentry).toBe(undefined);
      });
    });

    describe('when data-page is not defined in the body', () => {
      beforeEach(() => {
        delete document.body.dataset.page;
        initSentry();
      });

      it('calls Sentry.setTags with gon values', () => {
        mockSentryInit.mock.calls[0][0].initialScope(mockScope);

        expect(mockScope.setTags).toHaveBeenCalledTimes(1);
        expect(mockScope.setTags).toHaveBeenCalledWith(
          expect.objectContaining({
            page: undefined,
          }),
        );
      });

      it('Uses location.path to set browserTracingIntegration transaction name', () => {
        const mockBrowserTracingIntegration = jest.spyOn(Sentry, 'browserTracingIntegration');

        initSentry();

        const context = mockBrowserTracingIntegration.mock.calls[0][0].beforeStartSpan({
          op: 'pageload',
        });

        expect(context).toEqual({ op: 'pageload', name: window.location.pathname });
      });
    });
  });

  describe('isServerUnavailableError', () => {
    it('returns true for a ServerError with statusCode 503', () => {
      const error = new Error('Response not successful: Received status code 503');
      error.name = 'ServerError';
      error.statusCode = 503;

      expect(isServerUnavailableError({ originalException: error })).toBe(true);
    });

    it('returns false for a ServerError with a different status code', () => {
      const error = new Error('Response not successful: Received status code 500');
      error.name = 'ServerError';
      error.statusCode = 500;

      expect(isServerUnavailableError({ originalException: error })).toBe(false);
    });

    it('returns false for non-ServerError exceptions', () => {
      expect(isServerUnavailableError({ originalException: new TypeError('fail') })).toBe(false);
    });

    it('returns false when originalException is undefined', () => {
      expect(isServerUnavailableError({})).toBe(false);
    });

    it('returns false when hint is undefined', () => {
      expect(isServerUnavailableError(undefined)).toBe(false);
    });
  });

  describe('isNonActionableError', () => {
    const eventWithMessage = (value) => ({ exception: { values: [{ type: 'Error', value }] } });

    it('returns true when only the hint exception matches', () => {
      const error = new Error('Failed to fetch');

      expect(isNonActionableError({}, { originalException: error })).toBe(true);
    });

    it('returns true when originalException is a string', () => {
      expect(isNonActionableError({}, { originalException: 'Network Error' })).toBe(true);
    });

    it('returns true when only event.message matches', () => {
      expect(isNonActionableError({ message: 'Failed to fetch' })).toBe(true);
    });

    it('returns false for actionable application errors', () => {
      expect(isNonActionableError(eventWithMessage('Cannot read properties of undefined'))).toBe(
        false,
      );
      expect(isNonActionableError(eventWithMessage('x is not a function'))).toBe(false);
    });

    it('returns false when event has no exception, message, or hint', () => {
      expect(isNonActionableError({})).toBe(false);
      expect(isNonActionableError({}, undefined)).toBe(false);
      expect(isNonActionableError({}, {})).toBe(false);
    });
  });
});
