/* eslint-disable @gitlab/require-i18n-strings */

/**
 * Tracks snowplow event when User clicks on error link to Sentry
 * @param {String}  externalUrl that will be send as a property for the event
 */
export const trackClickErrorLinkToSentryOptions = (url) => ({
  category: 'Error Tracking',
  action: 'click_error_link_to_sentry',
  label: 'Error Link',
  property: url,
});

/**
 * Tracks snowplow event when user views error list
 */
export const trackErrorListViewsOptions = {
  category: 'Error Tracking',
  action: 'view_errors_list',
};

/**
 * Tracks snowplow event when user views error details
 */
export const trackErrorDetailsViewsOptions = {
  category: 'Error Tracking',
  action: 'view_error_details',
};

/**
 * Tracks snowplow event when error status is updated
 */
export const trackErrorStatusUpdateOptions = (status) => ({
  category: 'Error Tracking',
  action: `update_${status}_status`,
});
