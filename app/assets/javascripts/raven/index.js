import RavenConfig from './raven_config';

const index = function index() {
  RavenConfig.init({
    sentryDsn: gon.sentry_dsn,
    currentUserId: gon.current_user_id,
    whitelistUrls: [gon.gitlab_url],
    isProduction: gon.is_production,
  });

  return RavenConfig;
};

index();

export default index;
