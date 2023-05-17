import { masks } from '~/lib/dateformat';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const DATE_RANGE_LIMIT = 180;
export const PROJECTS_PER_PAGE = 50;

const { isoDate, mediumDate } = masks;
export const dateFormats = {
  isoDate,
  defaultDate: mediumDate,
  defaultDateTime: 'mmm d, yyyy h:MMtt',
  month: 'mmmm',
};

export const METRIC_POPOVER_LABEL = s__('ValueStreamAnalytics|View details');

export const KEY_METRICS = {
  LEAD_TIME: 'lead_time',
  CYCLE_TIME: 'cycle_time',
  ISSUES: 'issues',
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
  key: 'key_metrics',
  title: s__('ValueStreamAnalytics|Key metrics'),
  keys: Object.values(KEY_METRICS),
};

export const VSA_METRICS_GROUPS = [VSA_FLOW_METRICS_GROUP];

export const VULNERABILITY_CRITICAL_TYPE = 'vulnerability_critical';
export const VULNERABILITY_HIGH_TYPE = 'vulnerability_high';

export const VULNERABILITY_METRICS = {
  CRITICAL: VULNERABILITY_CRITICAL_TYPE,
  HIGH: VULNERABILITY_HIGH_TYPE,
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
  [KEY_METRICS.LEAD_TIME]: {
    description: s__('ValueStreamAnalytics|Median time from issue created to issue closed.'),
    groupLink: '-/analytics/value_stream_analytics',
    projectLink: '-/value_stream_analytics',
    docsLink: helpPagePath('user/analytics/value_stream_analytics', {
      anchor: 'view-the-lead-time-and-cycle-time-for-issues',
    }),
  },
  [KEY_METRICS.CYCLE_TIME]: {
    description: s__(
      "ValueStreamAnalytics|Median time from the earliest commit of a linked issue's merge request to when that issue is closed.",
    ),
    groupLink: '-/analytics/value_stream_analytics',
    projectLink: '-/value_stream_analytics',
    docsLink: helpPagePath('user/analytics/value_stream_analytics', {
      anchor: 'view-the-lead-time-and-cycle-time-for-issues',
    }),
  },
  [KEY_METRICS.ISSUES]: {
    description: s__('ValueStreamAnalytics|Number of new issues created.'),
    groupLink: '-/issues_analytics',
    projectLink: '-/analytics/issues_analytics',
    docsLink: helpPagePath('user/analytics/issue_analytics'),
  },
  [KEY_METRICS.DEPLOYS]: {
    description: s__('ValueStreamAnalytics|Total number of deploys to production.'),
    groupLink: '-/analytics/productivity_analytics',
    projectLink: '-/analytics/merge_request_analytics',
    docsLink: helpPagePath('user/analytics/merge_request_analytics'),
  },
  [VULNERABILITY_METRICS.CRITICAL]: {
    description: s__('ValueStreamAnalytics|Critical vulnerabilities over time.'),
    groupLink: '-/security/vulnerabilities',
    projectLink: '-/security/vulnerability_report',
    docsLink: helpPagePath('user/application_security/vulnerability_report/index'),
  },
  [VULNERABILITY_METRICS.HIGH]: {
    description: s__('ValueStreamAnalytics|High vulnerabilities over time.'),
    groupLink: '-/security/vulnerabilities',
    projectLink: '-/security/vulnerability_report',
    docsLink: helpPagePath('user/application_security/vulnerability_report/index'),
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
