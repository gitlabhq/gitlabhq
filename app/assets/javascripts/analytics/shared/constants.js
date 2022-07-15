import { masks } from 'dateformat';
import { s__ } from '~/locale';

export const DATE_RANGE_LIMIT = 180;
export const OFFSET_DATE_BY_ONE = 1;
export const PROJECTS_PER_PAGE = 50;

const { isoDate, mediumDate } = masks;
export const dateFormats = {
  isoDate,
  defaultDate: mediumDate,
  defaultDateTime: 'mmm d, yyyy h:MMtt',
  month: 'mmmm',
};

// Some content is duplicated due to backward compatibility.
// It will be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/350614 in 14.9
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

const KEY_METRICS_TITLE = s__('ValueStreamAnalytics|Key metrics');
const KEY_METRICS_KEYS = ['lead_time', 'cycle_time', 'issues', 'commits', 'deploys'];

const DORA_METRICS_TITLE = s__('ValueStreamAnalytics|DORA metrics');
const DORA_METRICS_KEYS = [
  'deployment_frequency',
  'lead_time_for_changes',
  'time_to_restore_service',
  'change_failure_rate',
];

export const VSA_METRICS_GROUPS = [
  { key: 'key_metrics', title: KEY_METRICS_TITLE, keys: KEY_METRICS_KEYS },
  { key: 'dora_metrics', title: DORA_METRICS_TITLE, keys: DORA_METRICS_KEYS },
];
