import * as Sentry from '~/sentry/sentry_browser_wrapper';

export const reportToSentry = (component, failureType) => {
  Sentry.captureException(failureType, {
    tags: {
      component,
    },
  });
};
