import {
  BrowserClient,
  defaultStackParser,
  makeFetchTransport,
  defaultIntegrations,
  BrowserTracing,

  // exports
  captureException,
  SDK_VERSION,
} from 'sentrybrowser';
import * as Sentry from 'sentrybrowser';

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

jest.mock('sentrybrowser', () => {
  return {
    ...jest.createMockFromModule('sentrybrowser'),

    // unmock actual configuration options
    defaultStackParser: jest.requireActual('sentrybrowser').defaultStackParser,
    makeFetchTransport: jest.requireActual('sentrybrowser').makeFetchTransport,
    defaultIntegrations: jest.requireActual('sentrybrowser').defaultIntegrations,
  };
});

describe('SentryConfig', () => {
  let mockBindClient;
  let mockSetTags;
  let mockSetUser;
  let mockBrowserClient;
  let mockStartSession;
  let mockCaptureSession;

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

    mockBindClient = jest.fn();
    mockSetTags = jest.fn();
    mockSetUser = jest.fn();
    mockStartSession = jest.fn();
    mockCaptureSession = jest.fn();
    mockBrowserClient = jest.spyOn(Sentry, 'BrowserClient');

    jest.spyOn(Sentry, 'getCurrentHub').mockReturnValue({
      bindClient: mockBindClient,
      setTags: mockSetTags,
      setUser: mockSetUser,
      startSession: mockStartSession,
      captureSession: mockCaptureSession,
    });
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

      it('creates BrowserClient with gon values and configuration', () => {
        expect(mockBrowserClient).toHaveBeenCalledWith(
          expect.objectContaining({
            dsn: mockDsn,
            release: mockRevision,
            allowUrls: [mockGitlabUrl, 'webpack-internal://'],
            environment: mockEnvironment,
            tracesSampleRate: mockSentryClientsideTracesSampleRate,
            tracePropagationTargets: [/^\//],

            transport: makeFetchTransport,
            stackParser: defaultStackParser,
            integrations: [...defaultIntegrations, expect.any(BrowserTracing)],
          }),
        );
      });

      it('Uses data-page to set BrowserTracing transaction name', () => {
        const context = BrowserTracing.mock.calls[0][0].beforeNavigate();

        expect(context).toMatchObject({ name: mockPage });
      });

      it('binds the BrowserClient to the hub', () => {
        expect(mockBindClient).toHaveBeenCalledTimes(1);
        expect(mockBindClient).toHaveBeenCalledWith(expect.any(BrowserClient));
      });

      it('calls Sentry.setTags with gon values', () => {
        expect(mockSetTags).toHaveBeenCalledTimes(1);
        expect(mockSetTags).toHaveBeenCalledWith({
          page: mockPage,
          version: mockVersion,
          feature_category: mockFeatureCategory,
        });
      });

      it('calls Sentry.setUser with gon values', () => {
        expect(mockSetUser).toHaveBeenCalledTimes(1);
        expect(mockSetUser).toHaveBeenCalledWith({
          id: mockCurrentUserId,
        });
      });

      it('sets global sentry', () => {
        // eslint-disable-next-line no-underscore-dangle
        expect(window._Sentry).toEqual({
          captureException,
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
        expect(mockSetUser).not.toHaveBeenCalled();
      });
    });

    describe('when gon is not defined', () => {
      beforeEach(() => {
        window.gon = undefined;
        initSentry();
      });

      it('Sentry.init is not called', () => {
        expect(mockBrowserClient).not.toHaveBeenCalled();
        expect(mockBindClient).not.toHaveBeenCalled();

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
        expect(mockBrowserClient).not.toHaveBeenCalled();
        expect(mockBindClient).not.toHaveBeenCalled();

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
        expect(mockSetTags).toHaveBeenCalledTimes(1);
        expect(mockSetTags).toHaveBeenCalledWith(
          expect.objectContaining({
            page: undefined,
          }),
        );
      });

      it('Uses location.path to set BrowserTracing transaction name', () => {
        const context = BrowserTracing.mock.calls[0][0].beforeNavigate({ op: 'pageload' });

        expect(context).toEqual({ op: 'pageload', name: window.location.pathname });
      });
    });
  });
});
