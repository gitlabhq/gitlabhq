import * as Sentry from '~/sentry/sentry_browser_wrapper';

export const reportToSentry = (component, error) => {
  Sentry.captureException(error, {
    tags: {
      component,
    },
  });
};
