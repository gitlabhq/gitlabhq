import '../webpack';

import * as Sentry from 'sentrybrowser7';
import SentryConfig from './sentry_config';

const index = function index() {
  // Configuration for newer versions of Sentry SDK (v7)
  SentryConfig.init({
    dsn: gon.sentry_dsn,
    environment: gon.sentry_environment,
    currentUserId: gon.current_user_id,
    allowUrls:
      process.env.NODE_ENV === 'production'
        ? [gon.gitlab_url]
        : [gon.gitlab_url, 'webpack-internal://'],
    release: gon.revision,
    tags: {
      revision: gon?.revision,
      feature_category: gon?.feature_category,
      page: document?.body?.dataset?.page,
    },
  });
};

index();

// The _Sentry object is globally exported so it can be used by
//   ./sentry_browser_wrapper.js
// This hack allows us to load a single version of `@sentry/browser`
// in the browser, see app/views/layouts/_head.html.haml to find how it is imported.

// eslint-disable-next-line no-underscore-dangle
window._Sentry = Sentry;

export default index;
