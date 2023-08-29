import * as Sentry from 'sentrybrowser';

const initSentry = function index() {
  if (!gon?.sentry_dsn) {
    return;
  }

  Sentry.init({
    dsn: gon.sentry_dsn,
    release: gon.version,
    allowUrls:
      process.env.NODE_ENV === 'production'
        ? [gon.gitlab_url]
        : [gon.gitlab_url, 'webpack-internal://'],
    environment: gon.sentry_environment,
  });

  Sentry.setTags({
    revision: gon.revision,
    feature_category: gon.feature_category,
    page: document?.body?.dataset?.page,
  });

  if (gon.current_user_id) {
    Sentry.setUser({
      id: gon.current_user_id,
    });
  }

  // The _Sentry object is globally exported so it can be used by
  //   ./sentry_browser_wrapper.js
  // This hack allows us to load a single version of `@sentry/browser`
  // in the browser, see app/views/layouts/_head.html.haml to find how it is imported.

  // eslint-disable-next-line no-underscore-dangle
  window._Sentry = Sentry;
};

export { initSentry };
