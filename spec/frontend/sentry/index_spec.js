import index from '~/sentry/index';

import LegacySentryConfig from '~/sentry/legacy_sentry_config';
import SentryConfig from '~/sentry/sentry_config';

describe('Sentry init', () => {
  const dsn = 'https://123@sentry.gitlab.test/123';
  const environment = 'test';
  const currentUserId = '1';
  const gitlabUrl = 'gitlabUrl';
  const revision = 'revision';
  const featureCategory = 'my_feature_category';

  beforeEach(() => {
    window.gon = {
      sentry_dsn: dsn,
      sentry_environment: environment,
      current_user_id: currentUserId,
      gitlab_url: gitlabUrl,
      revision,
      feature_category: featureCategory,
    };

    jest.spyOn(LegacySentryConfig, 'init').mockImplementation();
    jest.spyOn(SentryConfig, 'init').mockImplementation();
  });

  it('exports new version of Sentry in the global object', () => {
    // eslint-disable-next-line no-underscore-dangle
    expect(window._Sentry.SDK_VERSION).not.toMatch(/^5\./);
  });

  describe('when called', () => {
    beforeEach(() => {
      index();
    });

    it('configures sentry', () => {
      expect(SentryConfig.init).toHaveBeenCalledTimes(1);
      expect(SentryConfig.init).toHaveBeenCalledWith({
        dsn,
        currentUserId,
        allowUrls: [gitlabUrl, 'webpack-internal://'],
        environment,
        release: revision,
        tags: {
          revision,
          feature_category: featureCategory,
        },
      });
    });

    it('does not configure legacy sentry', () => {
      expect(LegacySentryConfig.init).not.toHaveBeenCalled();
    });
  });
});
