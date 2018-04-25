import { isProductionEnvironment } from '~/environment';
import RavenConfig from './raven_config';

const index = function index() {
  RavenConfig.init({
    sentryDsn: gon.sentry_dsn,
    currentUserId: gon.current_user_id,
    whitelistUrls: [gon.gitlab_url],
    isProduction: isProductionEnvironment(),
    release: gon.revision,
    tags: {
      revision: gon.revision,
    },
  });

  return RavenConfig;
};

index();

export default index;
