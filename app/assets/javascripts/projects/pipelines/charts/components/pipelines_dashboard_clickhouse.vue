<script>
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import { SOURCE_ANY, DATE_RANGE_7_DAYS, DATE_RANGES_AS_DAYS } from '../constants';
import getPipelineAnalytics from '../graphql/queries/get_pipeline_analytics.query.graphql';

import DashboardHeader from './dashboard_header.vue';
import PipelinesDashboardClickhouseFilters from './pipelines_dashboard_clickhouse_filters.vue';
import StatisticsList from './statistics_list.vue';
import PipelineDurationChart from './pipeline_duration_chart.vue';
import PipelineStatusChart from './pipeline_status_chart.vue';

export default {
  name: 'PipelinesDashboardClickhouse',
  components: {
    DashboardHeader,
    PipelinesDashboardClickhouseFilters,
    StatisticsList,
    PipelineDurationChart,
    PipelineStatusChart,
  },
  inject: {
    defaultBranch: {
      type: String,
      default: null,
    },
    projectPath: {
      type: String,
      default: '',
    },
    projectBranchCount: {
      type: Number,
      default: 0,
    },
  },
  data() {
    return {
      params: {
        source: SOURCE_ANY,
        dateRange: DATE_RANGE_7_DAYS,
        branch: this.defaultBranch,
      },
      pipelineAnalytics: {
        aggregate: {
          count: null,
          successCount: null,
          failedCount: null,
          durationStatistics: {
            p50: null,
          },
        },
        timeSeries: [],
      },
    };
  },
  apollo: {
    pipelineAnalytics: {
      query: getPipelineAnalytics,
      variables() {
        return this.variables;
      },
      update(data) {
        return data?.project?.pipelineAnalytics;
      },
      error() {
        createAlert({
          message: s__(
            'PipelineCharts|An error occurred while loading pipeline analytics. Please try refreshing the page.',
          ),
        });
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.pipelineAnalytics.loading;
    },
    variables() {
      // Use UTC time and take beginning of day
      const today = new Date(new Date().setUTCHours(0, 0, 0, 0));

      return {
        fullPath: this.projectPath,
        source: this.params.source === SOURCE_ANY ? null : this.params.source,
        branch: this.params.branch || null,
        fromTime: getDateInPast(today, DATE_RANGES_AS_DAYS[this.params.dateRange] || 7),
        toTime: today,
      };
    },
    formattedCounts() {
      const { count, successCount, failedCount, durationStatistics } =
        this.pipelineAnalytics.aggregate;
      return {
        total: count === null ? '-' : count,
        medianDuration: durationStatistics.p50,
        successRatio: Number(count) ? (successCount / count) * 100 : 0,
        failureRatio: Number(count) ? (failedCount / count) * 100 : 0,
      };
    },
  },
};
</script>
<template>
  <div>
    <dashboard-header>
      {{ s__('PipelineCharts|Pipelines') }}
    </dashboard-header>
    <pipelines-dashboard-clickhouse-filters
      v-model="params"
      :default-branch="defaultBranch"
      :project-path="projectPath"
      :project-branch-count="projectBranchCount"
    />
    <div>
      <statistics-list :loading="loading" :counts="formattedCounts" />
      <pipeline-duration-chart :loading="loading" :time-series="pipelineAnalytics.timeSeries" />
      <pipeline-status-chart :loading="loading" :time-series="pipelineAnalytics.timeSeries" />
    </div>
  </div>
</template>
