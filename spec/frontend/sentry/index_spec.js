import SentryConfig from '~/sentry/sentry_config';
import index from '~/sentry/index';

describe('SentryConfig options', () => {
  const dsn = 'https://123@sentry.gitlab.test/123';
  const currentUserId = 'currentUserId';
  const gitlabUrl = 'gitlabUrl';
  const environment = 'test';
  const revision = 'revision';
  let indexReturnValue;

  beforeEach(() => {
    window.gon = {
      sentry_dsn: dsn,
      sentry_environment: environment,
      current_user_id: currentUserId,
      gitlab_url: gitlabUrl,
      revision,
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
      },
    });
  });

  it('should return SentryConfig', () => {
    expect(indexReturnValue).toBe(SentryConfig);
  });
});
