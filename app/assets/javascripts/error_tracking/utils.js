/* eslint-disable @gitlab/i18n/no-non-i18n-strings, import/prefer-default-export */

/**
 * Tracks snowplow event when User clicks on error link to Sentry
 * @param {String}  externalUrl that will be send as a property for the event
 */
export const trackClickErrorLinkToSentryOptions = url => ({
  category: 'Error Tracking',
  action: 'click_error_link_to_sentry',
  label: 'Error Link',
  property: url,
});
