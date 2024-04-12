import dateFormat, { masks } from '~/lib/dateformat';
import {
  nDaysBefore,
  getStartOfDay,
  dayAfter,
  getDateInPast,
  getCurrentUtcDate,
  nWeeksBefore,
  nYearsBefore,
} from '~/lib/utils/datetime_utility';
import { s__, __, sprintf, n__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const DATE_RANGE_LIMIT = 180;
export const DEFAULT_DATE_RANGE = 29; // 30 including current date
export const PROJECTS_PER_PAGE = 50;

const { isoDate } = masks;
export const dateFormats = {
  isoDate,
  defaultDate: 'mmm dd, yyyy',
  defaultDateTime: 'mmm dd, yyyy h:MMtt',
  month: 'mmmm',
};

const TODAY = getCurrentUtcDate();
const TOMORROW = dayAfter(TODAY, { utc: true });
export const LAST_30_DAYS = getDateInPast(TOMORROW, 30, { utc: true });

const startOfToday = getStartOfDay(new Date(), { utc: true });
const lastXDays = __('Last %{days} days');
const lastWeek = nWeeksBefore(TOMORROW, 1, { utc: true });
const last90Days = getDateInPast(TOMORROW, 90, { utc: true });
const last180Days = getDateInPast(TOMORROW, DATE_RANGE_LIMIT, { utc: true });
const mrThroughputStartDate = nDaysBefore(startOfToday, DATE_RANGE_LIMIT, { utc: true });
const formatDateParam = (d) => dateFormat(d, dateFormats.isoDate, true);

export const DATE_RANGE_CUSTOM_VALUE = 'custom';
export const DATE_RANGE_LAST_30_DAYS_VALUE = 'last_30_days';

export const DEFAULT_DATE_RANGE_OPTIONS = [
  {
    text: __('Last week'),
    value: 'last_week',
    startDate: lastWeek,
    endDate: TODAY,
  },
  {
    text: sprintf(lastXDays, { days: 30 }),
    value: DATE_RANGE_LAST_30_DAYS_VALUE,
    startDate: LAST_30_DAYS,
    endDate: TODAY,
  },
  {
    text: sprintf(lastXDays, { days: 90 }),
    value: 'last_90_days',
    startDate: last90Days,
    endDate: TODAY,
  },
  {
    text: sprintf(lastXDays, { days: 180 }),
    value: 'last_180_days',
    startDate: last180Days,
    endDate: TODAY,
  },
];

export const MAX_DATE_RANGE_TEXT = (maxDateRange) => {
  return sprintf(
    __(
      'Showing data for workflow items completed in this date range. Date range limited to %{maxDateRange} days.',
    ),
    {
      maxDateRange,
    },
  );
};

export const NUMBER_OF_DAYS_SELECTED = (numDays) => {
  return n__('1 day selected', '%d days selected', numDays);
};

export const METRIC_POPOVER_LABEL = s__('ValueStreamAnalytics|View details');

export const ISSUES_COMPLETED_TYPE = 'issues_completed';

export const FLOW_METRICS = {
  LEAD_TIME: 'lead_time',
  CYCLE_TIME: 'cycle_time',
  ISSUES: 'issues',
  ISSUES_COMPLETED: ISSUES_COMPLETED_TYPE,
  COMMITS: 'commits',
  DEPLOYS: 'deploys',
};

export const DORA_METRICS = {
  DEPLOYMENT_FREQUENCY: 'deployment_frequency',
  LEAD_TIME_FOR_CHANGES: 'lead_time_for_changes',
  TIME_TO_RESTORE_SERVICE: 'time_to_restore_service',
  CHANGE_FAILURE_RATE: 'change_failure_rate',
};

const VSA_FLOW_METRICS_GROUP = {
  key: 'lifecycle_metrics',
  title: s__('ValueStreamAnalytics|Lifecycle metrics'),
  keys: Object.values(FLOW_METRICS),
};

export const VSA_METRICS_GROUPS = [VSA_FLOW_METRICS_GROUP];

export const VULNERABILITY_CRITICAL_TYPE = 'vulnerability_critical';
export const VULNERABILITY_HIGH_TYPE = 'vulnerability_high';

export const VULNERABILITY_METRICS = {
  CRITICAL: VULNERABILITY_CRITICAL_TYPE,
  HIGH: VULNERABILITY_HIGH_TYPE,
};

export const MERGE_REQUEST_THROUGHPUT_TYPE = 'merge_request_throughput';

export const MERGE_REQUEST_METRICS = {
  THROUGHPUT: MERGE_REQUEST_THROUGHPUT_TYPE,
};

export const CONTRIBUTOR_COUNT_TYPE = 'contributor_count';

export const CONTRIBUTOR_METRICS = {
  COUNT: CONTRIBUTOR_COUNT_TYPE,
};

export const AI_METRICS = {
  CODE_SUGGESTIONS_USAGE_RATE: 'code_suggestions_usage_rate',
};

export const METRIC_TOOLTIPS = {
  [DORA_METRICS.DEPLOYMENT_FREQUENCY]: {
    description: s__(
      'ValueStreamAnalytics|Average number of deployments to production per day. This metric measures how often value is delivered to end users.',
    ),
    groupLink: '-/analytics/ci_cd?tab=deployment-frequency',
    projectLink: '-/pipelines/charts?chart=deployment-frequency',
    docsLink: helpPagePath('user/analytics/dora_metrics', { anchor: 'deployment-frequency' }),
  },
  [DORA_METRICS.LEAD_TIME_FOR_CHANGES]: {
    description: s__(
      'ValueStreamAnalytics|The time to successfully deliver a commit into production. This metric reflects the efficiency of CI/CD pipelines.',
    ),
    groupLink: '-/analytics/ci_cd?tab=lead-time',
    projectLink: '-/pipelines/charts?chart=lead-time',
    docsLink: helpPagePath('user/analytics/dora_metrics', { anchor: 'lead-time-for-changes' }),
  },
  [DORA_METRICS.TIME_TO_RESTORE_SERVICE]: {
    description: s__(
      'ValueStreamAnalytics|The time it takes an organization to recover from a failure in production.',
    ),
    groupLink: '-/analytics/ci_cd?tab=time-to-restore-service',
    projectLink: '-/pipelines/charts?chart=time-to-restore-service',
    docsLink: helpPagePath('user/analytics/dora_metrics', { anchor: 'time-to-restore-service' }),
  },
  [DORA_METRICS.CHANGE_FAILURE_RATE]: {
    description: s__(
      'ValueStreamAnalytics|Percentage of deployments that cause an incident in production.',
    ),
    groupLink: '-/analytics/ci_cd?tab=change-failure-rate',
    projectLink: '-/pipelines/charts?chart=change-failure-rate',
    docsLink: helpPagePath('user/analytics/dora_metrics', { anchor: 'change-failure-rate' }),
  },
  [FLOW_METRICS.LEAD_TIME]: {
    description: s__('ValueStreamAnalytics|Median time from issue created to issue closed.'),
    groupLink: '-/analytics/value_stream_analytics',
    projectLink: '-/value_stream_analytics',
    docsLink: helpPagePath('user/analytics/value_stream_analytics', {
      anchor: 'view-the-lead-time-and-cycle-time-for-issues',
    }),
  },
  [FLOW_METRICS.CYCLE_TIME]: {
    description: s__(
      "ValueStreamAnalytics|Median time from the earliest commit of a linked issue's merge request to when that issue is closed.",
    ),
    groupLink: '-/analytics/value_stream_analytics',
    projectLink: '-/value_stream_analytics',
    docsLink: helpPagePath('user/analytics/value_stream_analytics', {
      anchor: 'view-the-lead-time-and-cycle-time-for-issues',
    }),
  },
  [FLOW_METRICS.ISSUES]: {
    description: s__('ValueStreamAnalytics|Number of new issues created.'),
    groupLink: '-/issues_analytics',
    projectLink: '-/analytics/issues_analytics',
    docsLink: helpPagePath('user/analytics/issue_analytics'),
  },
  [FLOW_METRICS.ISSUES_COMPLETED]: {
    description: s__('ValueStreamAnalytics|Number of issues closed by month.'),
    groupLink: '-/issues_analytics',
    projectLink: '-/analytics/issues_analytics',
    docsLink: helpPagePath('user/analytics/issue_analytics'),
  },
  [FLOW_METRICS.DEPLOYS]: {
    description: s__('ValueStreamAnalytics|Total number of deploys to production.'),
    groupLink: '-/analytics/productivity_analytics',
    projectLink: '-/analytics/merge_request_analytics',
    docsLink: helpPagePath('user/analytics/merge_request_analytics'),
  },
  [CONTRIBUTOR_METRICS.COUNT]: {
    description: s__(
      'ValueStreamAnalytics|Number of monthly unique users with contributions in the group.',
    ),
    groupLink: '-/contribution_analytics',
    docsLink: helpPagePath('user/profile/contributions_calendar.html', {
      anchor: 'user-contribution-events',
    }),
  },
  [VULNERABILITY_METRICS.CRITICAL]: {
    description: s__('ValueStreamAnalytics|Critical vulnerabilities over time.'),
    groupLink: '-/security/vulnerabilities?severity=CRITICAL',
    projectLink: '-/security/vulnerability_report?severity=CRITICAL',
    docsLink: helpPagePath('user/application_security/vulnerabilities/severities.html'),
  },
  [VULNERABILITY_METRICS.HIGH]: {
    description: s__('ValueStreamAnalytics|High vulnerabilities over time.'),
    groupLink: '-/security/vulnerabilities?severity=HIGH',
    projectLink: '-/security/vulnerability_report?severity=HIGH',
    docsLink: helpPagePath('user/application_security/vulnerabilities/severities.html'),
  },
  [MERGE_REQUEST_METRICS.THROUGHPUT]: {
    description: s__('ValueStreamAnalytics|The number of merge requests merged by month.'),
    groupLink: '-/analytics/productivity_analytics',
    projectLink: `-/analytics/merge_request_analytics?start_date=${formatDateParam(
      mrThroughputStartDate,
    )}&end_date=${formatDateParam(startOfToday)}`,
    docsLink: helpPagePath('user/analytics/merge_request_analytics', {
      anchor: 'view-the-number-of-merge-requests-in-a-date-range',
    }),
  },
  [AI_METRICS.CODE_SUGGESTIONS_USAGE_RATE]: {
    description: s__(
      'ValueStreamAnalytics|Monthly user engagement with AI Code Suggestions. Percentage ratio calculated as monthly unique Code Suggestions users / total monthly unique code contributors.',
    ),
    groupLink: '',
    projectLink: '',
    docsLink: helpPagePath('user/analytics'),
  },
};

// TODO: Remove this once the migration to METRIC_TOOLTIPS is complete
// https://gitlab.com/gitlab-org/gitlab/-/issues/388067
export const METRICS_POPOVER_CONTENT = {
  lead_time: {
    description: s__('ValueStreamAnalytics|Median time from issue created to issue closed.'),
  },
  cycle_time: {
    description: s__(
      "ValueStreamAnalytics|Median time from the earliest commit of a linked issue's merge request to when that issue is closed.",
    ),
  },
  lead_time_for_changes: {
    description: s__(
      'ValueStreamAnalytics|Median time between merge request merge and deployment to a production environment for all MRs deployed in the given time period.',
    ),
  },
  issues: { description: s__('ValueStreamAnalytics|Number of new issues created.') },
  deploys: { description: s__('ValueStreamAnalytics|Total number of deploys to production.') },
  deployment_frequency: {
    description: s__('ValueStreamAnalytics|Average number of deployments to production per day.'),
  },
  commits: {
    description: s__('ValueStreamAnalytics|Number of commits pushed to the default branch'),
  },
  time_to_restore_service: {
    description: s__(
      'ValueStreamAnalytics|Median time an incident was open on a production environment in the given time period.',
    ),
  },
  change_failure_rate: {
    description: s__(
      'ValueStreamAnalytics|Percentage of deployments that cause an incident in production.',
    ),
  },
};

export const USAGE_OVERVIEW_NO_DATA_ERROR = s__(
  'ValueStreamAnalytics|Failed to load usage overview data',
);

export const USAGE_OVERVIEW_DEFAULT_DATE_RANGE = {
  endDate: TODAY,
  startDate: nYearsBefore(TODAY, 1),
};

export const USAGE_OVERVIEW_IDENTIFIER_GROUPS = 'groups';
export const USAGE_OVERVIEW_IDENTIFIER_PROJECTS = 'projects';
export const USAGE_OVERVIEW_IDENTIFIER_USERS = 'users';
export const USAGE_OVERVIEW_IDENTIFIER_ISSUES = 'issues';
export const USAGE_OVERVIEW_IDENTIFIER_MERGE_REQUESTS = 'merge_requests';
export const USAGE_OVERVIEW_IDENTIFIER_PIPELINES = 'pipelines';

// Defines the constants used for querying the API as well as the order they appear
export const USAGE_OVERVIEW_METADATA = {
  [USAGE_OVERVIEW_IDENTIFIER_GROUPS]: { options: { title: __('Groups'), titleIcon: 'group' } },
  [USAGE_OVERVIEW_IDENTIFIER_PROJECTS]: {
    options: { title: __('Projects'), titleIcon: 'project' },
  },
  [USAGE_OVERVIEW_IDENTIFIER_USERS]: {
    options: { title: __('Users'), titleIcon: 'user' },
  },
  [USAGE_OVERVIEW_IDENTIFIER_ISSUES]: {
    options: { title: __('Issues'), titleIcon: 'issues' },
  },
  [USAGE_OVERVIEW_IDENTIFIER_MERGE_REQUESTS]: {
    options: { title: __('Merge requests'), titleIcon: 'merge-request' },
  },
  [USAGE_OVERVIEW_IDENTIFIER_PIPELINES]: {
    options: { title: __('Pipelines'), titleIcon: 'pipeline' },
  },
};

export const USAGE_OVERVIEW_QUERY_INCLUDE_KEYS = {
  [USAGE_OVERVIEW_IDENTIFIER_GROUPS]: 'includeGroups',
  [USAGE_OVERVIEW_IDENTIFIER_PROJECTS]: 'includeProjects',
  [USAGE_OVERVIEW_IDENTIFIER_USERS]: 'includeUsers',
  [USAGE_OVERVIEW_IDENTIFIER_ISSUES]: 'includeIssues',
  [USAGE_OVERVIEW_IDENTIFIER_MERGE_REQUESTS]: 'includeMergeRequests',
  [USAGE_OVERVIEW_IDENTIFIER_PIPELINES]: 'includePipelines',
};
