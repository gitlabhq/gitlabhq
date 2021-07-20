import * as Sentry from '@sentry/browser';
import SentryConfig from '~/sentry/sentry_config';

describe('SentryConfig', () => {
  describe('IGNORE_ERRORS', () => {
    it('should be an array of strings', () => {
      const areStrings = SentryConfig.IGNORE_ERRORS.every((error) => typeof error === 'string');

      expect(areStrings).toBe(true);
    });
  });

  describe('BLACKLIST_URLS', () => {
    it('should be an array of regexps', () => {
      const areRegExps = SentryConfig.BLACKLIST_URLS.every((url) => url instanceof RegExp);

      expect(areRegExps).toBe(true);
    });
  });

  describe('SAMPLE_RATE', () => {
    it('should be a finite number', () => {
      expect(typeof SentryConfig.SAMPLE_RATE).toEqual('number');
    });
  });

  describe('init', () => {
    const options = {
      currentUserId: 1,
    };

    beforeEach(() => {
      jest.spyOn(SentryConfig, 'configure');
      jest.spyOn(SentryConfig, 'bindSentryErrors');
      jest.spyOn(SentryConfig, 'setUser');

      SentryConfig.init(options);
    });

    it('should set the options property', () => {
      expect(SentryConfig.options).toEqual(options);
    });

    it('should call the configure method', () => {
      expect(SentryConfig.configure).toHaveBeenCalled();
    });

    it('should call the error bindings method', () => {
      expect(SentryConfig.bindSentryErrors).toHaveBeenCalled();
    });

    it('should call setUser', () => {
      expect(SentryConfig.setUser).toHaveBeenCalled();
    });

    it('should not call setUser if there is no current user ID', () => {
      SentryConfig.setUser.mockClear();
      options.currentUserId = undefined;

      SentryConfig.init(options);

      expect(SentryConfig.setUser).not.toHaveBeenCalled();
    });
  });

  describe('configure', () => {
    const sentryConfig = {};
    const options = {
      dsn: 'https://123@sentry.gitlab.test/123',
      whitelistUrls: ['//gitlabUrl', 'webpack-internal://'],
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
      sentryConfig.IGNORE_ERRORS = 'ignore_errors';
      sentryConfig.BLACKLIST_URLS = 'blacklist_urls';

      SentryConfig.configure.call(sentryConfig);
    });

    it('should call Sentry.init', () => {
      expect(Sentry.init).toHaveBeenCalledWith({
        dsn: options.dsn,
        release: options.release,
        sampleRate: 0.95,
        whitelistUrls: options.whitelistUrls,
        environment: 'test',
        ignoreErrors: sentryConfig.IGNORE_ERRORS,
        blacklistUrls: sentryConfig.BLACKLIST_URLS,
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
        sampleRate: 0.95,
        whitelistUrls: options.whitelistUrls,
        environment: 'development',
        ignoreErrors: sentryConfig.IGNORE_ERRORS,
        blacklistUrls: sentryConfig.BLACKLIST_URLS,
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

  describe('handleSentryErrors', () => {
    let event;
    let req;
    let config;
    let err;

    beforeEach(() => {
      event = {};
      req = { status: 'status', responseText: 'Unknown response text', statusText: 'statusText' };
      config = { type: 'type', url: 'url', data: 'data' };
      err = {};

      jest.spyOn(Sentry, 'captureMessage');

      SentryConfig.handleSentryErrors(event, req, config, err);
    });

    it('should call Sentry.captureMessage', () => {
      expect(Sentry.captureMessage).toHaveBeenCalledWith(err, {
        extra: {
          type: config.type,
          url: config.url,
          data: config.data,
          status: req.status,
          response: req.responseText,
          error: err,
          event,
        },
      });
    });

    describe('if no err is provided', () => {
      beforeEach(() => {
        SentryConfig.handleSentryErrors(event, req, config);
      });

      it('should use req.statusText as the error value', () => {
        expect(Sentry.captureMessage).toHaveBeenCalledWith(req.statusText, {
          extra: {
            type: config.type,
            url: config.url,
            data: config.data,
            status: req.status,
            response: req.responseText,
            error: req.statusText,
            event,
          },
        });
      });
    });

    describe('if no req.responseText is provided', () => {
      beforeEach(() => {
        req.responseText = undefined;

        SentryConfig.handleSentryErrors(event, req, config, err);
      });

      it('should use `Unknown response text` as the response', () => {
        expect(Sentry.captureMessage).toHaveBeenCalledWith(err, {
          extra: {
            type: config.type,
            url: config.url,
            data: config.data,
            status: req.status,
            response: 'Unknown response text',
            error: err,
            event,
          },
        });
      });
    });
  });
});
