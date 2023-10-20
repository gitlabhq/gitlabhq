import '../webpack';

import * as Sentry5 from 'sentrybrowser5';
import LegacySentryConfig from './legacy_sentry_config';

const index = function index() {
  // Configuration for legacy versions of Sentry SDK (v5)
  LegacySentryConfig.init({
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
};

index();

// The _Sentry object is globally exported so it can be used by
//   ./sentry_browser_wrapper.js
// This hack allows us to load a single version of `~/sentry/sentry_browser_wrapper`
// in the browser, see app/views/layouts/_head.html.haml to find how it is imported.

// eslint-disable-next-line no-underscore-dangle
window._Sentry = Sentry5;

export default index;
