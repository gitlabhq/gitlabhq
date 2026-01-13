<script>
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { DATE_RANGES_AS_DAYS, DATE_RANGE_DEFAULT, BRANCH_ANY } from '../constants';
import { updateQueryHistory, paramsFromQuery } from '../url_utils';
import getPipelineAnalytics from '../graphql/queries/get_pipeline_analytics.query.graphql';

import DashboardHeader from './dashboard_header.vue';
import PipelinesDashboardClickhouseFilters from './pipelines_dashboard_clickhouse_filters.vue';
import PipelinesStats from './pipelines_stats.vue';
import PipelineDurationChart from './pipeline_duration_chart.vue';
import PipelineStatusChart from './pipeline_status_chart.vue';

export default {
  name: 'PipelinesDashboardClickhouse',
  components: {
    DashboardHeader,
    PipelinesDashboardClickhouseFilters,
    PipelinesStats,
    PipelineDurationChart,
    PipelineStatusChart,
    JobAnalyticsTable: () =>
      import('ee_component/projects/pipelines/charts/components/job_analytics_table.vue'),
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
    failedPipelinesLink: {
      type: String,
      default: null,
    },
  },
  data() {
    const defaultParams = {
      source: null,
      branch: this.defaultBranch,
      dateRange: DATE_RANGE_DEFAULT,
      jobName: '',
    };

    return {
      defaultParams,
      params: paramsFromQuery(window.location.search, defaultParams),
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
    branchVariable() {
      const { branch } = this.params;
      if (!branch || branch === BRANCH_ANY) {
        return null;
      }
      return branch;
    },
    variables() {
      // Use UTC time and take beginning of day
      const today = new Date(new Date().setUTCHours(0, 0, 0, 0));

      return {
        fullPath: this.projectPath,
        source: this.params.source || null,
        branch: this.branchVariable,
        fromTime: getDateInPast(today, DATE_RANGES_AS_DAYS[this.params.dateRange] || 7),
        toTime: today,
        jobName: this.params.jobName || null,
      };
    },
    failedPipelinesPath() {
      if (this.branchVariable) {
        return mergeUrlParams({ ref: this.branchVariable }, this.failedPipelinesLink);
      }
      return this.failedPipelinesLink;
    },
  },
  mounted() {
    window.addEventListener('popstate', this.updateParamsFromQuery);
  },
  beforeDestroy() {
    window.removeEventListener('popstate', this.updateParamsFromQuery);
  },
  methods: {
    updateParamsFromQuery() {
      this.params = paramsFromQuery(window.location.search, this.defaultParams);
    },
    onFiltersInput(params) {
      this.params = { ...this.params, ...params };

      updateQueryHistory(this.params, this.defaultParams);
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
      :value="params"
      :default-branch="defaultBranch"
      :project-path="projectPath"
      :project-branch-count="projectBranchCount"
      @input="onFiltersInput($event)"
    />
    <div class="gl-flex gl-flex-col gl-gap-5">
      <pipelines-stats
        :loading="loading"
        :aggregate="pipelineAnalytics.aggregate"
        :failed-pipelines-path="failedPipelinesPath"
      />
      <pipeline-duration-chart :loading="loading" :time-series="pipelineAnalytics.timeSeries" />
      <pipeline-status-chart :loading="loading" :time-series="pipelineAnalytics.timeSeries" />
      <job-analytics-table :variables="variables" @filters-input="onFiltersInput($event)" />
    </div>
  </div>
</template>
