import * as Sentry from '@sentry/browser';

export const reportToSentry = (component, failureType) => {
  Sentry.captureException(failureType, {
    tags: {
      component,
    },
  });
};
