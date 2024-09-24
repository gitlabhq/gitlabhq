<script>
import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import { GlColumnChart, GlChartSeriesLabel } from '@gitlab/ui/dist/charts';
import { getDateInPast, localeDateFormat } from '~/lib/utils/datetime_utility';
import { __, s__ } from '~/locale';
import CiCdAnalyticsCharts from '~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_charts.vue';
import {
  DEFAULT,
  CHART_CONTAINER_HEIGHT,
  INNER_CHART_HEIGHT,
  ONE_WEEK_AGO_DAYS,
  ONE_MONTH_AGO_DAYS,
  ONE_YEAR_AGO_DAYS,
  X_AXIS_LABEL_ROTATION,
  X_AXIS_TITLE_OFFSET,
  PARSE_FAILURE,
  LOAD_ANALYTICS_FAILURE,
  LOAD_PIPELINES_FAILURE,
  UNSUPPORTED_DATA,
} from '../constants';
import getPipelineCountByStatus from '../graphql/queries/get_pipeline_count_by_status.query.graphql';
import getProjectPipelineStatistics from '../graphql/queries/get_project_pipeline_statistics.query.graphql';
import StatisticsList from './statistics_list.vue';

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
    GlChartSeriesLabel,
    GlSkeletonLoader,
    StatisticsList,
    CiCdAnalyticsCharts,
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
      tooltipTitle: '',
      tooltipContent: [],
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
      const { successfulPipelines, totalPipelines } = this.counts;
      const successfulCount = successfulPipelines?.count;
      const totalCount = totalPipelines?.count || 0;

      return totalCount === 0 ? 100 : (successfulCount / totalCount) * 100;
    },
    failureRatio() {
      const { failedPipelines, totalPipelines } = this.counts;
      const failedCount = failedPipelines?.count;
      const totalCount = totalPipelines?.count || 0;

      return totalCount === 0 ? 0 : (failedCount / totalCount) * 100;
    },
    formattedCounts() {
      const { totalPipelines } = this.counts;

      return {
        total: totalPipelines?.count,
        successRatio: this.successRatio,
        failureRatio: this.failureRatio,
      };
    },
    areaCharts() {
      const { lastWeek, lastMonth, lastYear } = this.$options.chartTitles;
      const { lastWeekRange, lastMonthRange, lastYearRange } = this.$options.chartRanges;
      const charts = [
        { title: lastWeek, range: lastWeekRange, data: this.lastWeekChartData },
        { title: lastMonth, range: lastMonthRange, data: this.lastMonthChartData },
        { title: lastYear, range: lastYearRange, data: this.lastYearChartData },
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
    chartOptions() {
      return {
        ...this.$options.timesChartOptions,
        yAxis: {
          axisLabel: {
            formatter: (value) => value,
          },
        },
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
    mergeLabelsAndValues(labels, values) {
      return labels.map((label, index) => [label, values[index]]);
    },
    buildAreaChartData({ title, data, range }) {
      const { labels, totals, success } = data;

      return {
        title,
        range,
        data: [
          {
            name: 'all',
            data: this.mergeLabelsAndValues(labels, totals),
          },
          {
            name: 'success',
            data: this.mergeLabelsAndValues(labels, success),
            areaStyle: {
              color: this.$options.successColor,
            },
            lineStyle: {
              color: this.$options.successColor,
            },
            itemStyle: {
              color: this.$options.successColor,
            },
          },
        ],
      };
    },
    formatTooltipText({ value, seriesData }) {
      this.tooltipTitle = value;
      this.tooltipContent = seriesData.map(({ seriesId, seriesName, color, value: metric }) => ({
        key: seriesId,
        name: seriesName,
        color,
        value: metric[1],
      }));
    },
  },
  successColor: '#366800',
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
      'PipelineCharts|An error has occurred when retrieving the analytics data',
    ),
    [LOAD_PIPELINES_FAILURE]: s__(
      'PipelineCharts|An error has occurred when retrieving the pipelines data',
    ),
    [PARSE_FAILURE]: s__('PipelineCharts|There was an error parsing the data for the charts.'),
    [DEFAULT]: s__('PipelineCharts|An unknown error occurred while processing CI/CD analytics.'),
  },
  chartTitles: {
    lastWeek: __('Last week'),
    lastMonth: __('Last month'),
    lastYear: __('Last year'),
  },
  get chartRanges() {
    const today = new Date();
    const pastDate = (timeScale) => getDateInPast(today, timeScale);
    return {
      lastWeekRange: localeDateFormat.asDate.formatRange(pastDate(ONE_WEEK_AGO_DAYS), today),
      lastMonthRange: localeDateFormat.asDate.formatRange(pastDate(ONE_MONTH_AGO_DAYS), today),
      lastYearRange: localeDateFormat.asDate.formatRange(pastDate(ONE_YEAR_AGO_DAYS), today),
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
      <h4>{{ s__('PipelineCharts|CI/CD Analytics') }}</h4>
    </div>
    <gl-skeleton-loader v-if="loading" :lines="5" />
    <statistics-list v-else :counts="formattedCounts" />
    <h4>{{ __('Pipelines charts') }}</h4>
    <ci-cd-analytics-charts
      :charts="areaCharts"
      :chart-options="$options.areaChartOptions"
      :format-tooltip-text="formatTooltipText"
    >
      <template #tooltip-title>{{ tooltipTitle }}</template>
      <template #tooltip-content>
        <div
          v-for="{ key, name, color, value } in tooltipContent"
          :key="key"
          class="gl-flex gl-justify-between"
        >
          <gl-chart-series-label class="gl-mr-7 gl-text-sm" :color="color">
            {{ name }}
          </gl-chart-series-label>
          <div class="gl-font-bold">{{ value }}</div>
        </div>
      </template>
    </ci-cd-analytics-charts>
    <h4 class="gl-mt-6">{{ __('Pipeline durations for the last 30 commits') }}</h4>
    <gl-column-chart
      :height="$options.chartContainerHeight"
      :option="chartOptions"
      :bars="timesChartTransformedData"
      :y-axis-title="__('Minutes')"
      :x-axis-title="__('Commit')"
      x-axis-type="category"
    />
  </div>
</template>
