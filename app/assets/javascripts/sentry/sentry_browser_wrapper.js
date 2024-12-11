/* eslint-disable no-console */

// The _Sentry object is globally exported so it can be used here
// This hack allows us to load a single version of `@sentry/browser`
// in the browser (or none).

// See app/views/layouts/_head.html.haml to find how it is imported.

// This module exports Sentry methods used by our production code.

/** @type {import('@sentry/core').captureException} */
export const captureException = (...args) => {
  // eslint-disable-next-line no-underscore-dangle
  const Sentry = window._Sentry;

  // When Sentry is not configured during development, show console error
  if (process.env.NODE_ENV === 'development' && !Sentry) {
    console.error('[Sentry stub]', 'captureException(...) called with:', { ...args });
    return;
  }

  Sentry?.captureException(...args);
};

/** @type {import('@sentry/core').addBreadcrumb} */
export const addBreadcrumb = (...args) => {
  // eslint-disable-next-line no-underscore-dangle
  const Sentry = window._Sentry;

  // When Sentry is not configured during development, show console error
  if (process.env.NODE_ENV === 'development' && !Sentry) {
    console.debug('[Sentry stub]', 'addBreadcrumb(...) called with:', { ...args });
    return;
  }

  Sentry?.addBreadcrumb(...args);
};
