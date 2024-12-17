/* eslint-disable no-restricted-imports */
import { captureException, addBreadcrumb, SDK_VERSION } from '@sentry/browser';
import * as Sentry from '@sentry/browser';

import { initSentry } from '~/sentry/init_sentry';

const mockDsn = 'https://123@sentry.gitlab.test/123';
const mockEnvironment = 'development';
const mockCurrentUserId = 1;
const mockGitlabUrl = 'https://gitlab.com';
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
            ignoreErrors: [/Network Error/i, /NetworkError/i],
            enableTracing: true,
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
          addBreadcrumb,
          SDK_VERSION,
        });
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
});
