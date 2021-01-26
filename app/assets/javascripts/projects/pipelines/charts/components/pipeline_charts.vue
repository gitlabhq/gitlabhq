<script>
import dateFormat from 'dateformat';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import getPipelineCountByStatus from '../graphql/queries/get_pipeline_count_by_status.query.graphql';
import getProjectPipelineStatistics from '../graphql/queries/get_project_pipeline_statistics.query.graphql';
import { __, s__, sprintf } from '~/locale';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import {
  DEFAULT,
  CHART_CONTAINER_HEIGHT,
  CHART_DATE_FORMAT,
  INNER_CHART_HEIGHT,
  ONE_WEEK_AGO_DAYS,
  ONE_MONTH_AGO_DAYS,
  X_AXIS_LABEL_ROTATION,
  X_AXIS_TITLE_OFFSET,
  PARSE_FAILURE,
  LOAD_ANALYTICS_FAILURE,
  LOAD_PIPELINES_FAILURE,
  UNSUPPORTED_DATA,
} from '../constants';
import StatisticsList from './statistics_list.vue';
import CiCdAnalyticsAreaChart from './ci_cd_analytics_area_chart.vue';

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
    GlColumnChart,
    GlSkeletonLoader,
    StatisticsList,
    CiCdAnalyticsAreaChart,
  },
  inject: {
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
    loading() {
      return this.$apollo.queries.counts.loading;
    },
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
    areaCharts() {
      const { lastWeek, lastMonth, lastYear } = this.$options.chartTitles;
      const charts = [
        { title: lastWeek, data: this.lastWeekChartData },
        { title: lastMonth, data: this.lastMonthChartData },
        { title: lastYear, data: this.lastYearChartData },
      ];
      let areaChartsData = [];

      try {
        areaChartsData = charts.map(this.buildAreaChartData);
      } catch {
        areaChartsData = [];
        this.reportFailure(PARSE_FAILURE);
      }

      return areaChartsData;
    },
    timesChartTransformedData() {
      return [
        {
          name: 'full',
          data: this.mergeLabelsAndValues(this.timesChartData.labels, this.timesChartData.values),
        },
      ];
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
    mergeLabelsAndValues(labels, values) {
      return labels.map((label, index) => [label, values[index]]);
    },
    buildAreaChartData({ title, data }) {
      const { labels, totals, success } = data;

      return {
        title,
        data: [
          {
            name: 'all',
            data: this.mergeLabelsAndValues(labels, totals),
          },
          {
            name: 'success',
            data: this.mergeLabelsAndValues(labels, success),
          },
        ],
      };
    },
  },
  chartContainerHeight: CHART_CONTAINER_HEIGHT,
  timesChartOptions: {
    height: INNER_CHART_HEIGHT,
    xAxis: {
      axisLabel: {
        rotate: X_AXIS_LABEL_ROTATION,
      },
      nameGap: X_AXIS_TITLE_OFFSET,
    },
  },
  areaChartOptions: {
    xAxis: {
      name: s__('Pipeline|Date'),
      type: 'category',
    },
    yAxis: {
      name: s__('Pipeline|Pipelines'),
      minInterval: 1,
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
  get chartTitles() {
    const today = dateFormat(new Date(), CHART_DATE_FORMAT);
    const pastDate = (timeScale) =>
      dateFormat(getDateInPast(new Date(), timeScale), CHART_DATE_FORMAT);
    return {
      lastWeek: sprintf(__('Pipelines for last week (%{oneWeekAgo} - %{today})'), {
        oneWeekAgo: pastDate(ONE_WEEK_AGO_DAYS),
        today,
      }),
      lastMonth: sprintf(__('Pipelines for last month (%{oneMonthAgo} - %{today})'), {
        oneMonthAgo: pastDate(ONE_MONTH_AGO_DAYS),
        today,
      }),
      lastYear: __('Pipelines for last year'),
    };
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="showFailureAlert" :variant="failure.variant" @dismiss="hideAlert">{{
      failure.text
    }}</gl-alert>
    <div class="gl-mb-3">
      <h3>{{ s__('PipelineCharts|CI / CD Analytics') }}</h3>
    </div>
    <h4 class="gl-my-4">{{ s__('PipelineCharts|Overall statistics') }}</h4>
    <div class="row">
      <div class="col-md-6">
        <gl-skeleton-loader v-if="loading" :lines="5" />
        <statistics-list v-else :counts="formattedCounts" />
      </div>
      <div v-if="!loading" class="col-md-6">
        <strong>{{ __('Duration for the last 30 commits') }}</strong>
        <gl-column-chart
          :height="$options.chartContainerHeight"
          :option="$options.timesChartOptions"
          :bars="timesChartTransformedData"
          :y-axis-title="__('Minutes')"
          :x-axis-title="__('Commit')"
          x-axis-type="category"
        />
      </div>
    </div>
    <template v-if="!loading">
      <hr />
      <h4 class="gl-my-4">{{ __('Pipelines charts') }}</h4>
      <ci-cd-analytics-area-chart
        v-for="(chart, index) in areaCharts"
        :key="index"
        :chart-data="chart.data"
        :area-chart-options="$options.areaChartOptions"
        >{{ chart.title }}</ci-cd-analytics-area-chart
      >
    </template>
  </div>
</template>
