<script>
import dateFormat from 'dateformat';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { __, sprintf } from '~/locale';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import StatisticsList from './statistics_list.vue';
import PipelinesAreaChart from './pipelines_area_chart.vue';
import {
  CHART_CONTAINER_HEIGHT,
  INNER_CHART_HEIGHT,
  X_AXIS_LABEL_ROTATION,
  X_AXIS_TITLE_OFFSET,
  CHART_DATE_FORMAT,
  ONE_WEEK_AGO_DAYS,
  ONE_MONTH_AGO_DAYS,
} from '../constants';

export default {
  components: {
    StatisticsList,
    GlColumnChart,
    PipelinesAreaChart,
  },
  props: {
    counts: {
      type: Object,
      required: true,
    },
    timesChartData: {
      type: Object,
      required: true,
    },
    lastWeekChartData: {
      type: Object,
      required: true,
    },
    lastMonthChartData: {
      type: Object,
      required: true,
    },
    lastYearChartData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      timesChartTransformedData: [
        {
          name: 'full',
          data: this.mergeLabelsAndValues(this.timesChartData.labels, this.timesChartData.values),
        },
      ],
    };
  },
  computed: {
    areaCharts() {
      const { lastWeek, lastMonth, lastYear } = this.$options.chartTitles;

      return [
        this.buildAreaChartData(lastWeek, this.lastWeekChartData),
        this.buildAreaChartData(lastMonth, this.lastMonthChartData),
        this.buildAreaChartData(lastYear, this.lastYearChartData),
      ];
    },
  },
  methods: {
    mergeLabelsAndValues(labels, values) {
      return labels.map((label, index) => [label, values[index]]);
    },
    buildAreaChartData(title, data) {
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
  get chartTitles() {
    const today = dateFormat(new Date(), CHART_DATE_FORMAT);
    const pastDate = timeScale =>
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
    <div class="mb-3">
      <h3>{{ s__('PipelineCharts|CI / CD Analytics') }}</h3>
    </div>
    <h4 class="my-4">{{ s__('PipelineCharts|Overall statistics') }}</h4>
    <div class="row">
      <div class="col-md-6">
        <statistics-list :counts="counts" />
      </div>
      <div class="col-md-6">
        <strong>
          {{ __('Duration for the last 30 commits') }}
        </strong>
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
    <hr />
    <h4 class="my-4">{{ __('Pipelines charts') }}</h4>
    <pipelines-area-chart
      v-for="(chart, index) in areaCharts"
      :key="index"
      :chart-data="chart.data"
    >
      {{ chart.title }}
    </pipelines-area-chart>
  </div>
</template>
