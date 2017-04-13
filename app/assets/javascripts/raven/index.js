import RavenConfig from './raven_config';

const index = RavenConfig.init.bind(RavenConfig, {
  sentryDsn: gon.sentry_dsn,
  currentUserId: gon.current_user_id,
  whitelistUrls: [gon.gitlab_url],
  isProduction: gon.is_production,
});

index();

export default index;
