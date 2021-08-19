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
