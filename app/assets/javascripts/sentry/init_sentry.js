/* eslint-disable no-restricted-imports */
import {
  init,
  browserSessionIntegration,
  browserTracingIntegration,

  // exports
  captureException,
  captureMessage,
  addBreadcrumb,
  SDK_VERSION,
} from '@sentry/browser';

export function isExternalOriginError(event) {
  const exception = event.exception?.values?.[0];
  if (!exception) return false;

  const frames = exception.stacktrace?.frames;
  if (!frames || frames.length === 0) return false;

  const gitlabUrl = window.gon?.gitlab_url;
  if (!gitlabUrl) return false;

  const assetHost = window.gon?.asset_host;

  return frames.every(
    (f) =>
      !f.filename ||
      f.filename === '<anonymous>' ||
      (!f.filename.startsWith(gitlabUrl) && !(assetHost && f.filename.startsWith(assetHost))),
  );
}

export function isServerUnavailableError(hint) {
  const error = hint?.originalException;
  if (!error) return false;

  return error.name === 'ServerError' && Number(error.statusCode) === 503;
}

// Patterns for errors that should never reach Sentry. These describe failures
// outside our control (user connectivity, expired sessions, server-side HTTP
// errors that need to be diagnosed where they originate and client created no ops).
// The matching JS exceptions have no in-app frames and the source of the problem cannot be
// fixed from the frontend code that observed the error.
//
// `ignoreErrors` only applies to events from the global error handler. The
// same patterns are also checked in `beforeSend` via `isNonActionableError`
// to cover events explicitly sent through `Sentry.captureException(...)`.
const NON_ACTIONABLE_ERROR_PATTERNS = [
  /Network Error/i,
  /NetworkError/i,
  /Failed to fetch/i,
  /Load failed/i,
  /NavigationDuplicated/,
  /You must be logged in/,
  /Request failed with status code \d+/,
  /Response not successful: Received status code \d+/,
];

export function isNonActionableError(event, hint) {
  const candidates = [
    event?.exception?.values?.[0]?.value,
    event?.message,
    hint?.originalException?.message,
    typeof hint?.originalException === 'string' ? hint.originalException : null,
  ];

  return candidates.some(
    (msg) => typeof msg === 'string' && NON_ACTIONABLE_ERROR_PATTERNS.some((re) => re.test(msg)),
  );
}

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

    beforeSend(event, hint) {
      if (isExternalOriginError(event)) return null;
      if (isServerUnavailableError(hint)) return null;
      if (isNonActionableError(event, hint)) return null;
      return event;
    },

    ignoreErrors: NON_ACTIONABLE_ERROR_PATTERNS,

    // Browser tracing configuration
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
    captureMessage,
    addBreadcrumb,
    SDK_VERSION, // used to verify compatibility with the Sentry instance
  };
};

export { initSentry };
