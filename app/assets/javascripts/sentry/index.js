import '../webpack';

import SentryConfig from './sentry_config';

const index = function index() {
  SentryConfig.init({
    dsn: gon.sentry_dsn,
    currentUserId: gon.current_user_id,
    whitelistUrls:
      process.env.NODE_ENV === 'production'
        ? [gon.gitlab_url]
        : [gon.gitlab_url, 'webpack-internal://'],
    environment: gon.sentry_environment,
    release: gon.revision,
    tags: {
      revision: gon.revision,
      feature_category: gon.feature_category,
    },
  });

  return SentryConfig;
};

index();

export default index;
