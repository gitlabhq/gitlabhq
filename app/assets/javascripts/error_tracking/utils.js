/* eslint-disable @gitlab/i18n/no-non-i18n-strings */

/**
 * Tracks snowplow event when user clicks View in Sentry btn
 * @param {String}  externalUrl that will be send as a property for the event
 */
export const trackViewInSentryOptions = url => ({
  category: 'Error Tracking',
  action: 'click_view_in_sentry',
  label: 'External Url',
  property: url,
});

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
