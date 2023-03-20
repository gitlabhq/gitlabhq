import * as Sentry from 'sentrybrowser7';

import SentryConfig from '~/sentry/sentry_config';

describe('SentryConfig', () => {
  describe('init', () => {
    const options = {
      currentUserId: 1,
    };

    beforeEach(() => {
      jest.spyOn(SentryConfig, 'configure');
      jest.spyOn(SentryConfig, 'setUser');

      SentryConfig.init(options);
    });

    it('should set the options property', () => {
      expect(SentryConfig.options).toEqual(options);
    });

    it('should call the configure method', () => {
      expect(SentryConfig.configure).toHaveBeenCalled();
    });

    it('should call setUser', () => {
      expect(SentryConfig.setUser).toHaveBeenCalled();
    });

    it('should not call setUser if there is no current user ID', () => {
      SentryConfig.setUser.mockClear();
      SentryConfig.init({ currentUserId: undefined });

      expect(SentryConfig.setUser).not.toHaveBeenCalled();
    });
  });

  describe('configure', () => {
    const sentryConfig = {};
    const options = {
      dsn: 'https://123@sentry.gitlab.test/123',
      allowUrls: ['//gitlabUrl', 'webpack-internal://'],
      environment: 'test',
      release: 'revision',
      tags: {
        revision: 'revision',
        feature_category: 'my_feature_category',
      },
    };

    beforeEach(() => {
      jest.spyOn(Sentry, 'init').mockImplementation();
      jest.spyOn(Sentry, 'setTags').mockImplementation();

      sentryConfig.options = options;

      SentryConfig.configure.call(sentryConfig);
    });

    it('should call Sentry.init', () => {
      expect(Sentry.init).toHaveBeenCalledWith({
        dsn: options.dsn,
        release: options.release,
        allowUrls: options.allowUrls,
        environment: options.environment,
      });
    });

    it('should call Sentry.setTags', () => {
      expect(Sentry.setTags).toHaveBeenCalledWith(options.tags);
    });

    it('should set environment from options', () => {
      sentryConfig.options.environment = 'development';

      SentryConfig.configure.call(sentryConfig);

      expect(Sentry.init).toHaveBeenCalledWith({
        dsn: options.dsn,
        release: options.release,
        allowUrls: options.allowUrls,
        environment: 'development',
      });
    });
  });

  describe('setUser', () => {
    let sentryConfig;

    beforeEach(() => {
      sentryConfig = { options: { currentUserId: 1 } };
      jest.spyOn(Sentry, 'setUser');

      SentryConfig.setUser.call(sentryConfig);
    });

    it('should call .setUser', () => {
      expect(Sentry.setUser).toHaveBeenCalledWith({
        id: sentryConfig.options.currentUserId,
      });
    });
  });
});
