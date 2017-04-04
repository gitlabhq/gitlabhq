import RavenConfig from './raven_config';

RavenConfig.init({
  sentryDsn: gon.sentry_dsn,
  currentUserId: gon.current_user_id,
  whitelistUrls: [gon.gitlab_url],
  isProduction: gon.is_production,
});

export default RavenConfig;
