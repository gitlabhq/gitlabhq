import Tracking from '~/tracking';

/**
 * The value of 1 in count, means there was one action performed
 * related to the tracked action, in either of the following categories
 * 1. Refreshing the logs
 * 2. Select an environment
 * 3. Change the time range
 * 4. Use the search bar
 */
const trackLogs = (label) =>
  Tracking.event(document.body.dataset.page, 'logs_view', {
    label,
    property: 'count',
    value: 1,
  });

export default trackLogs;
