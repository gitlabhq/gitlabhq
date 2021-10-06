import * as Sentry from '@sentry/browser';

/**
 * capture anything starting with http:// or https://
 *   https?:\/\/
 *
 * up until a disallowed character or whitespace
 *   [^"<>()\\^`{|}\s]+
 *
 * and a disallowed character or whitespace, including non-ending chars .,:;!?
 *   [^"<>()\\^`{|}\s.,:;!?]
 */
export const linkRegex = /(https?:\/\/[^"<>()\\^`{|}\s]+[^"<>()\\^`{|}\s.,:;!?])/g;
export default { linkRegex };

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
