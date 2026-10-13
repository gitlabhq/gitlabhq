<script>
import { isNumber } from 'lodash-es';
import { isInTimePeriod } from '~/lib/utils/datetime/date_calculation_utility';
import { formatNumber, n__, sprintf } from '~/locale';
import { INDIVIDUAL_CHART_HEIGHT } from '../constants';
import ContributorAreaChart from './contributor_area_chart.vue';

export default {
  name: 'IndividualChart',
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
    showLineChanges: {
      type: Boolean,
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
      return this.sumDataInZoom(this.contributor.commitDates, this.contributor.commits);
    },
    additionsCount() {
      if (!this.showLineChanges) return 0;

      return this.sumDataInZoom(this.contributor.additionsDates, this.contributor.additions);
    },
    deletionsCount() {
      if (!this.showLineChanges) return 0;

      return this.sumDataInZoom(this.contributor.deletionsDates, this.contributor.deletions);
    },
    commitCountText() {
      return sprintf(
        n__(
          'ContributionAnalytics|%{count} commit',
          'ContributionAnalytics|%{count} commits',
          this.commitCount,
        ),
        {
          count: formatNumber(this.commitCount),
        },
      );
    },
    additionsText() {
      return sprintf(
        n__(
          'ContributionAnalytics|%{count} addition',
          'ContributionAnalytics|%{count} additions',
          this.additionsCount,
        ),
        {
          count: formatNumber(this.additionsCount),
        },
      );
    },
    deletionsText() {
      return sprintf(
        n__(
          'ContributionAnalytics|%{count} deletion',
          'ContributionAnalytics|%{count} deletions',
          this.deletionsCount,
        ),
        {
          count: formatNumber(this.deletionsCount),
        },
      );
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
    sumDataInZoom(data, total) {
      if (!this.hasZoom) return total;

      const start = new Date(this.zoom.startValue);
      const end = new Date(this.zoom.endValue);

      return data
        .filter(([date, count]) => count > 0 && isInTimePeriod(new Date(date), start, end))
        .map(([, count]) => count)
        .reduce((acc, count) => acc + count, 0);
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
  <div class="gl-col-lg-6 gl-col-12 gl-my-5 gl-min-w-0">
    <h4 class="gl-mb-2 gl-mt-0 gl-break-words" data-testid="chart-header">
      {{ contributor.name }}
    </h4>
    <div class="gl-mb-3">
      <p class="gl-mb-0 gl-break-words" data-testid="commit-count">
        {{ commitCountText }} ({{ contributor.email }})
      </p>
      <p v-if="showLineChanges" class="gl-mb-0 gl-break-words" data-testid="line-change-count">
        <span class="gl-text-success">+{{ additionsText }}</span>
        <span>&nbsp;/&nbsp;</span>
        <span class="gl-text-danger">-{{ deletionsText }}</span>
      </p>
    </div>
    <contributor-area-chart
      :data="contributor.dates"
      :option="chartOptions"
      :height="$options.INDIVIDUAL_CHART_HEIGHT"
      @created="onChartCreated"
    />
  </div>
</template>
