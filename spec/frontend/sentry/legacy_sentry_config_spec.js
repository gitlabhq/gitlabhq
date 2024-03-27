import * as Sentry5 from 'sentrybrowser5';
import LegacySentryConfig from '~/sentry/legacy_sentry_config';

describe('LegacySentryConfig', () => {
  describe('IGNORE_ERRORS', () => {
    it('should be an array of strings', () => {
      const areStrings = LegacySentryConfig.IGNORE_ERRORS.every(
        (error) => typeof error === 'string',
      );

      expect(areStrings).toBe(true);
    });
  });

  describe('DENYLIST_URLS', () => {
    it('should be an array of regexps', () => {
      const areRegExps = LegacySentryConfig.DENYLIST_URLS.every((url) => url instanceof RegExp);

      expect(areRegExps).toBe(true);
    });
  });

  describe('SAMPLE_RATE', () => {
    it('should be a finite number', () => {
      expect(typeof LegacySentryConfig.SAMPLE_RATE).toEqual('number');
    });
  });

  describe('init', () => {
    const options = {
      currentUserId: 1,
    };

    beforeEach(() => {
      jest.spyOn(LegacySentryConfig, 'configure');
      jest.spyOn(LegacySentryConfig, 'bindSentryErrors');
      jest.spyOn(LegacySentryConfig, 'setUser');

      LegacySentryConfig.init(options);
    });

    it('should set the options property', () => {
      expect(LegacySentryConfig.options).toEqual(options);
    });

    it('should call the configure method', () => {
      expect(LegacySentryConfig.configure).toHaveBeenCalled();
    });

    it('should call the error bindings method', () => {
      expect(LegacySentryConfig.bindSentryErrors).toHaveBeenCalled();
    });

    it('should call setUser', () => {
      expect(LegacySentryConfig.setUser).toHaveBeenCalled();
    });

    it('should not call setUser if there is no current user ID', () => {
      LegacySentryConfig.setUser.mockClear();
      options.currentUserId = undefined;

      LegacySentryConfig.init(options);

      expect(LegacySentryConfig.setUser).not.toHaveBeenCalled();
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
      jest.spyOn(Sentry5, 'init').mockImplementation();
      jest.spyOn(Sentry5, 'setTags').mockImplementation();

      sentryConfig.options = options;
      sentryConfig.IGNORE_ERRORS = 'ignore_errors';
      sentryConfig.DENYLIST_URLS = 'blacklist_urls';

      LegacySentryConfig.configure.call(sentryConfig);
    });

    it('should call Sentry5.init', () => {
      expect(Sentry5.init).toHaveBeenCalledWith({
        dsn: options.dsn,
        release: options.release,
        sampleRate: 0.95,
        whitelistUrls: options.whitelistUrls,
        environment: 'test',
        ignoreErrors: sentryConfig.IGNORE_ERRORS,
        blacklistUrls: sentryConfig.DENYLIST_URLS,
      });
    });

    it('should call Sentry5.setTags', () => {
      expect(Sentry5.setTags).toHaveBeenCalledWith(options.tags);
    });

    it('should set environment from options', () => {
      sentryConfig.options.environment = 'development';

      LegacySentryConfig.configure.call(sentryConfig);

      expect(Sentry5.init).toHaveBeenCalledWith({
        dsn: options.dsn,
        release: options.release,
        sampleRate: 0.95,
        whitelistUrls: options.whitelistUrls,
        environment: 'development',
        ignoreErrors: sentryConfig.IGNORE_ERRORS,
        blacklistUrls: sentryConfig.DENYLIST_URLS,
      });
    });
  });

  describe('setUser', () => {
    let sentryConfig;

    beforeEach(() => {
      sentryConfig = { options: { currentUserId: 1 } };
      jest.spyOn(Sentry5, 'setUser');

      LegacySentryConfig.setUser.call(sentryConfig);
    });

    it('should call .setUser', () => {
      expect(Sentry5.setUser).toHaveBeenCalledWith({
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

      jest.spyOn(Sentry5, 'captureMessage');

      LegacySentryConfig.handleSentryErrors(event, req, config, err);
    });

    it('should call Sentry5.captureMessage', () => {
      expect(Sentry5.captureMessage).toHaveBeenCalledWith(err, {
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
        LegacySentryConfig.handleSentryErrors(event, req, config);
      });

      it('should use req.statusText as the error value', () => {
        expect(Sentry5.captureMessage).toHaveBeenCalledWith(req.statusText, {
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

        LegacySentryConfig.handleSentryErrors(event, req, config, err);
      });

      it('should use `Unknown response text` as the response', () => {
        expect(Sentry5.captureMessage).toHaveBeenCalledWith(err, {
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
