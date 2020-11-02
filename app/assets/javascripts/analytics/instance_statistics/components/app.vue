<script>
import { s__ } from '~/locale';
import InstanceCounts from './instance_counts.vue';
import InstanceStatisticsCountChart from './instance_statistics_count_chart.vue';
import UsersChart from './users_chart.vue';
import pipelinesStatsQuery from '../graphql/queries/pipeline_stats.query.graphql';
import issuesAndMergeRequestsQuery from '../graphql/queries/issues_and_merge_requests.query.graphql';
import ProjectsAndGroupsChart from './projects_and_groups_chart.vue';
import { TODAY, TOTAL_DAYS_TO_SHOW, START_DATE } from '../constants';

const PIPELINES_KEY_TO_NAME_MAP = {
  total: s__('InstanceAnalytics|Total'),
  succeeded: s__('InstanceAnalytics|Succeeded'),
  failed: s__('InstanceAnalytics|Failed'),
  canceled: s__('InstanceAnalytics|Canceled'),
  skipped: s__('InstanceAnalytics|Skipped'),
};
const ISSUES_AND_MERGE_REQUESTS_KEY_TO_NAME_MAP = {
  issues: s__('InstanceAnalytics|Issues'),
  mergeRequests: s__('InstanceAnalytics|Merge Requests'),
};
const loadPipelineChartError = s__(
  'InstanceAnalytics|Could not load the pipelines chart. Please refresh the page to try again.',
);
const loadIssuesAndMergeRequestsChartError = s__(
  'InstanceAnalytics|Could not load the issues and merge requests chart. Please refresh the page to try again.',
);
const noDataMessage = s__('InstanceAnalytics|There is no data available.');

export default {
  name: 'InstanceStatisticsApp',
  components: {
    InstanceCounts,
    InstanceStatisticsCountChart,
    UsersChart,
    ProjectsAndGroupsChart,
  },
  TOTAL_DAYS_TO_SHOW,
  START_DATE,
  TODAY,
  configs: [
    {
      keyToNameMap: PIPELINES_KEY_TO_NAME_MAP,
      prefix: 'pipelines',
      loadChartError: loadPipelineChartError,
      noDataMessage,
      chartTitle: s__('InstanceAnalytics|Pipelines'),
      yAxisTitle: s__('InstanceAnalytics|Items'),
      xAxisTitle: s__('InstanceAnalytics|Month'),
      query: pipelinesStatsQuery,
    },
    {
      keyToNameMap: ISSUES_AND_MERGE_REQUESTS_KEY_TO_NAME_MAP,
      prefix: 'issuesAndMergeRequests',
      loadChartError: loadIssuesAndMergeRequestsChartError,
      noDataMessage,
      chartTitle: s__('InstanceAnalytics|Issues & Merge Requests'),
      yAxisTitle: s__('InstanceAnalytics|Items'),
      xAxisTitle: s__('InstanceAnalytics|Month'),
      query: issuesAndMergeRequestsQuery,
    },
  ],
};
</script>

<template>
  <div>
    <instance-counts />
    <users-chart
      :start-date="$options.START_DATE"
      :end-date="$options.TODAY"
      :total-data-points="$options.TOTAL_DAYS_TO_SHOW"
    />
    <projects-and-groups-chart
      :start-date="$options.START_DATE"
      :end-date="$options.TODAY"
      :total-data-points="$options.TOTAL_DAYS_TO_SHOW"
    />
    <instance-statistics-count-chart
      v-for="chartOptions in $options.configs"
      :key="chartOptions.chartTitle"
      :prefix="chartOptions.prefix"
      :key-to-name-map="chartOptions.keyToNameMap"
      :query="chartOptions.query"
      :x-axis-title="chartOptions.xAxisTitle"
      :y-axis-title="chartOptions.yAxisTitle"
      :load-chart-error-message="chartOptions.loadChartError"
      :no-data-message="chartOptions.noDataMessage"
      :chart-title="chartOptions.chartTitle"
    />
  </div>
</template>
