// The _Sentry object is globally exported so it can be used here
// This hack allows us to load a single version of `@sentry/browser`
// in the browser (or none). See app/views/layouts/_head.html.haml
// to find how it is imported.

// This module wraps methods used by our production code.
// Each export is names as we cannot export the entire namespace from *.
export const captureException = (...args) => {
  // eslint-disable-next-line no-underscore-dangle
  const Sentry = window._Sentry;

  Sentry?.captureException(...args);
};

export const captureMessage = (...args) => {
  // eslint-disable-next-line no-underscore-dangle
  const Sentry = window._Sentry;

  Sentry?.captureMessage(...args);
};

export const withScope = (...args) => {
  // eslint-disable-next-line no-underscore-dangle
  const Sentry = window._Sentry;

  Sentry?.withScope(...args);
};
