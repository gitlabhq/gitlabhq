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

jest.mock('sentrybrowser');

describe('SentryConfig', () => {
  beforeEach(() => {
    window.gon = {
      sentry_dsn: mockDsn,
      sentry_environment: mockEnvironment,
      current_user_id: mockCurrentUserId,
      gitlab_url: mockGitlabUrl,
      version: mockVersion,
      revision: mockRevision,
      feature_category: mockFeatureCategory,
    };

    document.body.dataset.page = mockPage;
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

      it('calls Sentry.init with gon values', () => {
        expect(Sentry.init).toHaveBeenCalledTimes(1);
        expect(Sentry.init).toHaveBeenCalledWith({
          dsn: mockDsn,
          release: mockVersion,
          allowUrls: [mockGitlabUrl, 'webpack-internal://'],
          environment: mockEnvironment,
        });
      });

      it('calls Sentry.setTags with gon values', () => {
        expect(Sentry.setTags).toHaveBeenCalledTimes(1);
        expect(Sentry.setTags).toHaveBeenCalledWith({
          page: mockPage,
          revision: mockRevision,
          feature_category: mockFeatureCategory,
        });
      });

      it('calls Sentry.setUser with gon values', () => {
        expect(Sentry.setUser).toHaveBeenCalledTimes(1);
        expect(Sentry.setUser).toHaveBeenCalledWith({
          id: mockCurrentUserId,
        });
      });

      it('sets global sentry', () => {
        // eslint-disable-next-line no-underscore-dangle
        expect(window._Sentry).toBe(Sentry);
      });
    });

    describe('when user is not logged in', () => {
      beforeEach(() => {
        window.gon.current_user_id = undefined;
        initSentry();
      });

      it('does not call Sentry.setUser', () => {
        expect(Sentry.setUser).not.toHaveBeenCalled();
      });
    });

    describe('when gon is not defined', () => {
      beforeEach(() => {
        window.gon = undefined;
        initSentry();
      });

      it('Sentry.init is not called', () => {
        expect(Sentry.init).not.toHaveBeenCalled();
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
        expect(Sentry.init).not.toHaveBeenCalled();
        // eslint-disable-next-line no-underscore-dangle
        expect(window._Sentry).toBe(undefined);
      });
    });
  });
});
