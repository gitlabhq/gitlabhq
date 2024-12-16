/* eslint-disable no-restricted-imports */
import {
  init,
  browserSessionIntegration,
  browserTracingIntegration,

  // exports
  captureException,
  addBreadcrumb,
  SDK_VERSION,
} from '@sentry/browser';

const initSentry = () => {
  if (!gon?.sentry_dsn) {
    return;
  }

  const page = document?.body?.dataset?.page;

  init({
    dsn: gon.sentry_dsn,
    release: gon.revision,
    allowUrls:
      process.env.NODE_ENV === 'production'
        ? [gon.gitlab_url]
        : [gon.gitlab_url, 'webpack-internal://'],
    environment: gon.sentry_environment,

    ignoreErrors: [
      // Network errors create noise in Sentry and can't be fixed, ignore them.
      /Network Error/i,
      /NetworkError/i,
    ],

    // Browser tracing configuration
    enableTracing: true,
    tracePropagationTargets: [/^\//], // only trace internal requests
    tracesSampleRate: gon.sentry_clientside_traces_sample_rate || 0,
    integrations: [
      browserSessionIntegration(),
      browserTracingIntegration({
        beforeStartSpan(context) {
          return {
            ...context,
            // `page` acts as transaction name for performance tracing.
            // If missing, use default Sentry behavior: window.location.pathname
            name: page || window?.location?.pathname,
          };
        },
      }),
    ],
    initialScope(scope) {
      scope.setTags({
        version: gon.version,
        feature_category: gon.feature_category,
        page,
      });

      if (gon.current_user_id) {
        scope.setUser({
          id: gon.current_user_id,
        });
      }

      return scope;
    },
  });

  // The _Sentry object is globally exported so it can be used by
  //   ./sentry_browser_wrapper.js
  // This hack allows us to load a single version of `~/sentry/sentry_browser_wrapper`
  // in the browser, see app/views/layouts/_head.html.haml to find how it is imported.
  // eslint-disable-next-line no-underscore-dangle
  window._Sentry = {
    captureException,
    addBreadcrumb,
    SDK_VERSION, // used to verify compatibility with the Sentry instance
  };
};

export { initSentry };
