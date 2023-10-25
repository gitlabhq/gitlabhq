import {
  BrowserClient,
  getCurrentHub,
  defaultStackParser,
  makeFetchTransport,
  defaultIntegrations,
  BrowserTracing,

  // exports
  captureException,
  SDK_VERSION,
} from 'sentrybrowser';

const initSentry = () => {
  if (!gon?.sentry_dsn) {
    return;
  }

  const hub = getCurrentHub();

  const page = document?.body?.dataset?.page;

  const client = new BrowserClient({
    // Sentry.init(...) options
    dsn: gon.sentry_dsn,
    release: gon.revision,
    allowUrls:
      process.env.NODE_ENV === 'production'
        ? [gon.gitlab_url]
        : [gon.gitlab_url, 'webpack-internal://'],
    environment: gon.sentry_environment,

    // Browser tracing configuration
    tracePropagationTargets: [/^\//], // only trace internal requests
    tracesSampleRate: gon.sentry_clientside_traces_sample_rate || 0,

    // This configuration imitates the Sentry.init() default configuration
    // https://github.com/getsentry/sentry-javascript/blob/7.66.0/MIGRATION.md#explicit-client-options
    transport: makeFetchTransport,
    stackParser: defaultStackParser,
    integrations: [
      ...defaultIntegrations,
      new BrowserTracing({
        beforeNavigate(context) {
          return {
            ...context,
            // `page` acts as transaction name for performance tracing.
            // If missing, use default Sentry behavior: window.location.pathname
            name: page || window?.location?.pathname,
          };
        },
      }),
    ],
  });

  hub.bindClient(client);

  hub.setTags({
    version: gon.version,
    feature_category: gon.feature_category,
    page,
  });

  if (gon.current_user_id) {
    hub.setUser({
      id: gon.current_user_id,
    });
  }

  // The option `autoSessionTracking` is only avaialble on Sentry.init
  // this manually starts a session in a similar way.
  // See: https://github.com/getsentry/sentry-javascript/blob/7.66.0/packages/browser/src/sdk.ts#L204
  hub.startSession({ ignoreDuration: true }); // `ignoreDuration` counts only the page view.
  hub.captureSession();

  // The _Sentry object is globally exported so it can be used by
  //   ./sentry_browser_wrapper.js
  // This hack allows us to load a single version of `~/sentry/sentry_browser_wrapper`
  // in the browser, see app/views/layouts/_head.html.haml to find how it is imported.

  // eslint-disable-next-line no-underscore-dangle
  window._Sentry = {
    captureException,
    SDK_VERSION, // used to verify compatibility with the Sentry instance
  };
};

export { initSentry };
