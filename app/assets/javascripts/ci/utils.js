import * as Sentry from '@sentry/browser';

export const reportToSentry = (component, failureType) => {
  Sentry.withScope((scope) => {
    scope.setTag('component', component);
    Sentry.captureException(failureType);
  });
};

export const reportMessageToSentry = (component, message, context) => {
  Sentry.withScope((scope) => {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    scope.setContext('Vue data', context);
    scope.setTag('component', component);
    Sentry.captureMessage(message);
  });
};
