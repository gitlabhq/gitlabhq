<script>
import { isNumber } from 'lodash';
import { isInTimePeriod } from '~/lib/utils/datetime/date_calculation_utility';
import { INDIVIDUAL_CHART_HEIGHT } from '../constants';
import ContributorAreaChart from './contributor_area_chart.vue';

export default {
  INDIVIDUAL_CHART_HEIGHT,
  components: {
    ContributorAreaChart,
  },
  props: {
    contributor: {
      type: Object,
      required: true,
    },
    chartOptions: {
      type: Object,
      required: true,
    },
    zoom: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      chart: null,
    };
  },
  computed: {
    hasZoom() {
      const { startValue, endValue } = this.zoom;
      return isNumber(startValue) && isNumber(endValue);
    },
    commitCount() {
      if (!this.hasZoom) return this.contributor.commits;

      const start = new Date(this.zoom.startValue);
      const end = new Date(this.zoom.endValue);

      return this.contributor.dates[0].data
        .filter(([date, count]) => count > 0 && isInTimePeriod(new Date(date), start, end))
        .map(([, count]) => count)
        .reduce((acc, count) => acc + count, 0);
    },
  },
  watch: {
    chart() {
      this.syncChartZoom();
    },
    zoom() {
      this.syncChartZoom();
    },
  },
  methods: {
    onChartCreated(chart) {
      this.chart = chart;
    },
    syncChartZoom() {
      if (!this.hasZoom || !this.chart) return;

      const { startValue, endValue } = this.zoom;
      this.chart.setOption(
        { dataZoom: { startValue, endValue, show: false } },
        { lazyUpdate: true },
      );
    },
  },
};
</script>

<template>
  <div class="col-lg-6 col-12 gl-my-5">
    <h4 class="gl-mb-2 gl-mt-0" data-testid="chart-header">{{ contributor.name }}</h4>
    <p class="gl-mb-3" data-testid="commit-count">
      {{ n__('%d commit', '%d commits', commitCount) }} ({{ contributor.email }})
    </p>
    <contributor-area-chart
      :data="contributor.dates"
      :option="chartOptions"
      :height="$options.INDIVIDUAL_CHART_HEIGHT"
      @created="onChartCreated"
    />
  </div>
</template>
