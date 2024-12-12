import { DORA_METRICS, VALUE_STREAM_METRIC_TILE_METADATA } from '~/analytics/shared/constants';

export const mockLastVulnerabilityCountData = {
  date: '2020-05-20',
  critical: 7,
  high: 6,
  medium: 5,
  low: 4,
};

const deploymentFrequency = {
  ...VALUE_STREAM_METRIC_TILE_METADATA[DORA_METRICS.DEPLOYMENT_FREQUENCY],
  label: 'Deployment frequency',
  identifier: DORA_METRICS.DEPLOYMENT_FREQUENCY,
  value: 23.75,
};

const changeFailureRate = {
  ...VALUE_STREAM_METRIC_TILE_METADATA[DORA_METRICS.CHANGE_FAILURE_RATE],
  label: 'Change failure rate',
  identifier: DORA_METRICS.CHANGE_FAILURE_RATE,
  value: 0.056578947368421055,
};

const leadTimeForChanges = {
  ...VALUE_STREAM_METRIC_TILE_METADATA[DORA_METRICS.LEAD_TIME_FOR_CHANGES],
  label: 'Lead time for changes',
  identifier: DORA_METRICS.LEAD_TIME_FOR_CHANGES,
  value: 23508,
};

const timeToRestoreService = {
  ...VALUE_STREAM_METRIC_TILE_METADATA[DORA_METRICS.TIME_TO_RESTORE_SERVICE],
  label: 'Time to restore service',
  identifier: DORA_METRICS.TIME_TO_RESTORE_SERVICE,
  value: 72080,
};

export const mockDoraMetricsResponseData = {
  metrics: [
    {
      date: null,
      deployment_frequency: deploymentFrequency.value,
      change_failure_rate: changeFailureRate.value,
      lead_time_for_changes: leadTimeForChanges.value,
      time_to_restore_service: timeToRestoreService.value,
      __typename: 'DoraMetric',
    },
  ],
  __typename: 'Dora',
};

const issues = {
  unit: null,
  value: 10,
  identifier: 'issues',
  links: [],
  title: 'New issues',
  __typename: 'ValueStreamAnalyticsMetric',
};

const cycleTime = {
  unit: 'days',
  value: null,
  identifier: 'cycle_time',
  links: [],
  title: 'Cycle time',
  __typename: 'ValueStreamAnalyticsMetric',
};

const leadTime = {
  unit: 'days',
  value: 10,
  identifier: 'lead_time',
  links: [
    {
      label: 'Dashboard',
      name: 'Lead time',
      docsLink: null,
      url: '/groups/test-graphql-dora/-/issues_analytics',
      __typename: 'ValueStreamMetricLinkType',
    },
    {
      label: 'Go to docs',
      name: 'Lead time',
      docsLink: true,
      url: '/help/user/analytics/index#definitions',
      __typename: 'ValueStreamMetricLinkType',
    },
  ],
  title: 'Lead time',
  __typename: 'ValueStreamAnalyticsMetric',
};

const deploys = {
  unit: null,
  value: 751,
  identifier: 'deploys',
  links: [],
  title: 'Deploys',
  __typename: 'ValueStreamAnalyticsMetric',
};

export const rawMetricData = [
  issues,
  cycleTime,
  leadTime,
  deploys,
  deploymentFrequency,
  changeFailureRate,
  leadTimeForChanges,
  timeToRestoreService,
];

export const mockMetricTilesData = rawMetricData.map(({ value, ...rest }) => ({
  ...rest,
  value: !value ? '-' : value,
}));

export const mockFlowMetricsResponseData = {
  issues,
  issues_completed: {
    unit: 'issues',
    value: 109,
    identifier: 'issues_completed',
    links: [
      {
        label: 'Dashboard',
        name: 'Issues Completed',
        docsLink: null,
        url: '/groups/toolbox/-/issues_analytics',
        __typename: 'ValueStreamMetricLinkType',
      },
      {
        label: 'Go to docs',
        name: 'Issues Completed',
        docsLink: true,
        url: '/help/user/analytics/index#definitions',
        __typename: 'ValueStreamMetricLinkType',
      },
    ],
    title: 'Issues Completed',
    __typename: 'ValueStreamAnalyticsMetric',
  },
  cycle_time: cycleTime,
  lead_time: leadTime,
  deploys,
  median_time_to_merge: {
    unit: 'days',
    value: '0.3',
    identifier: 'median_time_to_merge',
    links: [],
    title: 'Time to Merge',
    __typename: 'ValueStreamAnalyticsMetric',
  },
  __typename: 'GroupValueStreamAnalyticsFlowMetrics',
};

export const mockFOSSFlowMetricsResponseData = {
  issues,
  deploys,
  __typename: 'ProjectValueStreamAnalyticsFlowMetrics',
};

export const mockFlowMetricsCommitsResponseData = {
  identifier: 'commits',
  links: [],
  title: 'Commits',
  value: '10',
};
