export const BUCKETING_INTERVAL_ALL = 'ALL';
export const BUCKETING_INTERVAL_MONTHLY = 'MONTHLY';

/**
 * Available filters for the flow metrics query, along with date range filters
 * NOTE: these additional do not apply to the `deploymentCount` field
 */
export const FLOW_METRICS_QUERY_FILTERS = [
  'labelNames',
  'projectIds',
  'assigneeUsernames',
  'milestoneTitle',
  'authorUsername',
];
