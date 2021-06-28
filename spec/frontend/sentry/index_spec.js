import index from '~/sentry/index';
import SentryConfig from '~/sentry/sentry_config';

describe('SentryConfig options', () => {
  const dsn = 'https://123@sentry.gitlab.test/123';
  const currentUserId = 'currentUserId';
  const gitlabUrl = 'gitlabUrl';
  const environment = 'test';
  const revision = 'revision';
  const featureCategory = 'my_feature_category';

  let indexReturnValue;

  beforeEach(() => {
    window.gon = {
      sentry_dsn: dsn,
      sentry_environment: environment,
      current_user_id: currentUserId,
      gitlab_url: gitlabUrl,
      revision,
      feature_category: featureCategory,
    };

    process.env.HEAD_COMMIT_SHA = revision;

    jest.spyOn(SentryConfig, 'init').mockImplementation();

    indexReturnValue = index();
  });

  it('should init with .sentryDsn, .currentUserId, .whitelistUrls and environment', () => {
    expect(SentryConfig.init).toHaveBeenCalledWith({
      dsn,
      currentUserId,
      whitelistUrls: [gitlabUrl, 'webpack-internal://'],
      environment,
      release: revision,
      tags: {
        revision,
        feature_category: featureCategory,
      },
    });
  });

  it('should return SentryConfig', () => {
    expect(indexReturnValue).toBe(SentryConfig);
  });
});
