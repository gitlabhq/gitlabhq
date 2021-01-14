<script>
import { GlAlert, GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import getPipelineCountByStatus from '../graphql/queries/get_pipeline_count_by_status.query.graphql';
import getProjectPipelineStatistics from '../graphql/queries/get_project_pipeline_statistics.query.graphql';
import PipelineCharts from './pipeline_charts.vue';

import {
  DEFAULT,
  LOAD_ANALYTICS_FAILURE,
  LOAD_PIPELINES_FAILURE,
  PARSE_FAILURE,
  UNSUPPORTED_DATA,
} from '../constants';

const defaultAnalyticsValues = {
  weekPipelinesTotals: [],
  weekPipelinesLabels: [],
  weekPipelinesSuccessful: [],
  monthPipelinesLabels: [],
  monthPipelinesTotals: [],
  monthPipelinesSuccessful: [],
  yearPipelinesLabels: [],
  yearPipelinesTotals: [],
  yearPipelinesSuccessful: [],
  pipelineTimesLabels: [],
  pipelineTimesValues: [],
};

const defaultCountValues = {
  totalPipelines: {
    count: 0,
  },
  successfulPipelines: {
    count: 0,
  },
};

export default {
  components: {
    GlAlert,
    GlTabs,
    GlTab,
    PipelineCharts,
    DeploymentFrequencyCharts: () =>
      import('ee_component/projects/pipelines/charts/components/deployment_frequency_charts.vue'),
  },
  inject: {
    shouldRenderDeploymentFrequencyCharts: {
      type: Boolean,
      default: false,
    },
    projectPath: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      showFailureAlert: false,
      failureType: null,
      analytics: { ...defaultAnalyticsValues },
      counts: { ...defaultCountValues },
    };
  },
  apollo: {
    counts: {
      query: getPipelineCountByStatus,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        return data?.project;
      },
      error() {
        this.reportFailure(LOAD_PIPELINES_FAILURE);
      },
    },
    analytics: {
      query: getProjectPipelineStatistics,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        return data?.project?.pipelineAnalytics;
      },
      error() {
        this.reportFailure(LOAD_ANALYTICS_FAILURE);
      },
    },
  },
  computed: {
    failure() {
      switch (this.failureType) {
        case LOAD_ANALYTICS_FAILURE:
          return {
            text: this.$options.errorTexts[LOAD_ANALYTICS_FAILURE],
            variant: 'danger',
          };
        case PARSE_FAILURE:
          return {
            text: this.$options.errorTexts[PARSE_FAILURE],
            variant: 'danger',
          };
        case UNSUPPORTED_DATA:
          return {
            text: this.$options.errorTexts[UNSUPPORTED_DATA],
            variant: 'info',
          };
        default:
          return {
            text: this.$options.errorTexts[DEFAULT],
            variant: 'danger',
          };
      }
    },
    lastWeekChartData() {
      return {
        labels: this.analytics.weekPipelinesLabels,
        totals: this.analytics.weekPipelinesTotals,
        success: this.analytics.weekPipelinesSuccessful,
      };
    },
    lastMonthChartData() {
      return {
        labels: this.analytics.monthPipelinesLabels,
        totals: this.analytics.monthPipelinesTotals,
        success: this.analytics.monthPipelinesSuccessful,
      };
    },
    lastYearChartData() {
      return {
        labels: this.analytics.yearPipelinesLabels,
        totals: this.analytics.yearPipelinesTotals,
        success: this.analytics.yearPipelinesSuccessful,
      };
    },
    timesChartData() {
      return {
        labels: this.analytics.pipelineTimesLabels,
        values: this.analytics.pipelineTimesValues,
      };
    },
    successRatio() {
      const { successfulPipelines, failedPipelines } = this.counts;
      const successfulCount = successfulPipelines?.count;
      const failedCount = failedPipelines?.count;
      const ratio = (successfulCount / (successfulCount + failedCount)) * 100;

      return failedCount === 0 ? 100 : ratio;
    },
    formattedCounts() {
      const { totalPipelines, successfulPipelines, failedPipelines } = this.counts;

      return {
        total: totalPipelines?.count,
        success: successfulPipelines?.count,
        failed: failedPipelines?.count,
        successRatio: this.successRatio,
      };
    },
  },
  methods: {
    hideAlert() {
      this.showFailureAlert = false;
    },
    reportFailure(type) {
      this.showFailureAlert = true;
      this.failureType = type;
    },
  },
  errorTexts: {
    [LOAD_ANALYTICS_FAILURE]: s__(
      'PipelineCharts|An error has ocurred when retrieving the analytics data',
    ),
    [LOAD_PIPELINES_FAILURE]: s__(
      'PipelineCharts|An error has ocurred when retrieving the pipelines data',
    ),
    [PARSE_FAILURE]: s__('PipelineCharts|There was an error parsing the data for the charts.'),
    [DEFAULT]: s__('PipelineCharts|An unknown error occurred while processing CI/CD analytics.'),
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="showFailureAlert" :variant="failure.variant" @dismiss="hideAlert">{{
      failure.text
    }}</gl-alert>
    <gl-tabs v-if="shouldRenderDeploymentFrequencyCharts">
      <gl-tab :title="__('Pipelines')">
        <pipeline-charts
          :counts="formattedCounts"
          :last-week="lastWeekChartData"
          :last-month="lastMonthChartData"
          :last-year="lastYearChartData"
          :times-chart="timesChartData"
          :loading="$apollo.queries.counts.loading"
          @report-failure="reportFailure"
        />
      </gl-tab>
      <gl-tab :title="__('Deployments')">
        <deployment-frequency-charts />
      </gl-tab>
    </gl-tabs>
    <pipeline-charts
      v-else
      :counts="formattedCounts"
      :last-week="lastWeekChartData"
      :last-month="lastMonthChartData"
      :last-year="lastYearChartData"
      :times-chart="timesChartData"
      :loading="$apollo.queries.counts.loading"
      @report-failure="reportFailure"
    />
  </div>
</template>
