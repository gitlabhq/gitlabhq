import { InternalEvents } from '~/tracking';

const category = 'Error Tracking'; // eslint-disable-line @gitlab/require-i18n-strings

function sendTrackingEvents(action, integrated) {
  InternalEvents.trackEvent(
    action,
    {
      variant: integrated ? 'integrated' : 'external',
    },
    category,
  );
}

/**
 * Tracks snowplow event when User clicks on error link to Sentry
 * @param {String}  externalUrl that will be send as a property for the event
 */
export const trackClickErrorLinkToSentryOptions = (url) => ({
  category,
  action: 'click_error_link_to_sentry',
  label: 'Error Link', // eslint-disable-line @gitlab/require-i18n-strings
  property: url,
});

/**
 * Tracks snowplow event when user views error list
 */

export const trackErrorListViewsOptions = (integrated) => {
  sendTrackingEvents('view_errors_list', integrated);
};

/**
 * Tracks snowplow event when user views error details
 */
export const trackErrorDetailsViewsOptions = (integrated) => {
  sendTrackingEvents('view_error_details', integrated);
};

/**
 * Tracks snowplow event when error status is updated
 */
export const trackErrorStatusUpdateOptions = (status, integrated) => {
  sendTrackingEvents(`update_${status}_status`, integrated);
};

/**
 * Tracks snowplow event when error list is filter by status
 */
export const trackErrorStatusFilterOptions = (status, integrated) => {
  sendTrackingEvents(`filter_${status}_status`, integrated);
};

/**
 * Tracks snowplow event when error list is sorted by field
 */
export const trackErrorSortedByField = (field, integrated) => {
  sendTrackingEvents(`sort_by_${field}`, integrated);
};

/**
 * Tracks snowplow event when the Create Issue button is clicked
 */
export const trackCreateIssueFromError = (integrated) => {
  sendTrackingEvents('click_create_issue_from_error', integrated);
};
