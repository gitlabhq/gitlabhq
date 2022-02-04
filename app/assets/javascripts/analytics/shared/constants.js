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
  'lead-time': {
    description: s__('ValueStreamAnalytics|Median time from issue created to issue closed.'),
  },
  lead_time: {
    description: s__('ValueStreamAnalytics|Median time from issue created to issue closed.'),
  },
  'cycle-time': {
    description: s__(
      "ValueStreamAnalytics|Median time from the earliest commit of a linked issue's merge request to when that issue is closed.",
    ),
  },
  cycle_time: {
    description: s__(
      "ValueStreamAnalytics|Median time from the earliest commit of a linked issue's merge request to when that issue is closed.",
    ),
  },
  'lead-time-for-changes': {
    description: s__(
      'ValueStreamAnalytics|Median time between merge request merge and deployment to a production environment for all MRs deployed in the given time period.',
    ),
  },
  lead_time_for_changes: {
    description: s__(
      'ValueStreamAnalytics|Median time between merge request merge and deployment to a production environment for all MRs deployed in the given time period.',
    ),
  },
  issues: { description: s__('ValueStreamAnalytics|Number of new issues created.') },
  'new-issue': { description: s__('ValueStreamAnalytics|Number of new issues created.') },
  'new-issues': { description: s__('ValueStreamAnalytics|Number of new issues created.') },
  deploys: { description: s__('ValueStreamAnalytics|Total number of deploys to production.') },
  'deployment-frequency': {
    description: s__('ValueStreamAnalytics|Average number of deployments to production per day.'),
  },
  deployment_frequency: {
    description: s__('ValueStreamAnalytics|Average number of deployments to production per day.'),
  },
  commits: {
    description: s__('ValueStreamAnalytics|Number of commits pushed to the default branch'),
  },
};
