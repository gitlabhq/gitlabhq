import RavenConfig from './raven_config';

const index = function index() {
  RavenConfig.init({
    sentryDsn: gon.sentry_dsn,
    currentUserId: gon.current_user_id,
    whitelistUrls:
      process.env.NODE_ENV === 'production'
        ? [gon.gitlab_url]
        : [gon.gitlab_url, 'webpack-internal://'],
    environment: gon.sentry_environment,
    release: gon.revision,
    tags: {
      revision: gon.revision,
    },
  });

  return RavenConfig;
};

index();

export default index;
