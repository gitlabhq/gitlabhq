<script>
import dateFormat from 'dateformat';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { GlSkeletonLoader } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import {
  CHART_CONTAINER_HEIGHT,
  CHART_DATE_FORMAT,
  INNER_CHART_HEIGHT,
  ONE_WEEK_AGO_DAYS,
  ONE_MONTH_AGO_DAYS,
  X_AXIS_LABEL_ROTATION,
  X_AXIS_TITLE_OFFSET,
  PARSE_FAILURE,
} from '../constants';
import StatisticsList from './statistics_list.vue';
import CiCdAnalyticsAreaChart from './ci_cd_analytics_area_chart.vue';

export default {
  components: {
    GlColumnChart,
    GlSkeletonLoader,
    StatisticsList,
    CiCdAnalyticsAreaChart,
  },
  props: {
    counts: {
      required: true,
      type: Object,
    },
    loading: {
      required: false,
      default: false,
      type: Boolean,
    },
    lastWeek: {
      required: true,
      type: Object,
    },
    lastMonth: {
      required: true,
      type: Object,
    },
    lastYear: {
      required: true,
      type: Object,
    },
    timesChart: {
      required: true,
      type: Object,
    },
  },
  computed: {
    areaCharts() {
      const { lastWeek, lastMonth, lastYear } = this.$options.chartTitles;
      const charts = [
        { title: lastWeek, data: this.lastWeek },
        { title: lastMonth, data: this.lastMonth },
        { title: lastYear, data: this.lastYear },
      ];
      let areaChartsData = [];

      try {
        areaChartsData = charts.map(this.buildAreaChartData);
      } catch {
        areaChartsData = [];
        this.vm.$emit('report-failure', PARSE_FAILURE);
      }

      return areaChartsData;
    },
    timesChartTransformedData() {
      return [
        {
          name: 'full',
          data: this.mergeLabelsAndValues(this.timesChart.labels, this.timesChart.values),
        },
      ];
    },
  },
  methods: {
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
    <div class="gl-mb-3">
      <h3>{{ s__('PipelineCharts|CI / CD Analytics') }}</h3>
    </div>
    <h4 class="gl-my-4">{{ s__('PipelineCharts|Overall statistics') }}</h4>
    <div class="row">
      <div class="col-md-6">
        <gl-skeleton-loader v-if="loading" :lines="5" />
        <statistics-list v-else :counts="counts" />
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
