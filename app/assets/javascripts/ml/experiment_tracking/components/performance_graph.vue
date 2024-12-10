<script>
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { s__ } from '~/locale';

export default {
  name: 'PerformanceGraph',
  components: { GlLineChart },
  props: {
    candidates: {
      type: Array,
      required: true,
    },
    metricNames: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      tooltipTitle: null,
      tooltipValue: null,
    };
  },
  i18n: {
    xAxisLabel: s__('ExperimentTracking|Candidate'),
    yAxisLabel: s__('ExperimentTracking|Metric value'),
  },
  computed: {
    graphData() {
      return this.metricNames.map((metric) => {
        return {
          name: metric,
          data: this.candidates
            .filter((candidate) => candidate[metric] !== undefined && candidate[metric] !== null)
            .map((candidate, index) => ({
              value: [index + 1, parseFloat(candidate[metric])],
              name: candidate.name,
            })),
        };
      });
    },
    graphOptions() {
      return {
        animation: true,
        xAxis: { name: this.$options.i18n.xAxisLabel, type: 'category' },
        yAxis: { name: this.$options.i18n.yAxisLabel, type: 'value' },
        dataZoom: [
          {
            type: 'slider',
            startValue: 0,
            minSpan: 1,
            minSpanValue: 1,
          },
        ],
        toolbox: { show: true },
      };
    },
  },
  methods: {
    formatTooltipText(params) {
      this.tooltipTitle = params.seriesData[0].name;
      this.tooltipValue = params.seriesData.map((item) => ({
        title: item.seriesName,
        value: item.data.value[1],
      }));
    },
  },
};
</script>

<template>
  <gl-line-chart
    :data="graphData"
    :option="graphOptions"
    show-legend
    :include-legend-avg-max="false"
    :format-tooltip-text="formatTooltipText"
    :height="null"
  >
    <template #tooltip-title> {{ tooltipTitle }} </template>
    <template #tooltip-content>
      <div class="gl-flex gl-flex-col">
        <div v-for="metric in tooltipValue" :key="metric.title" class="gl-flex gl-justify-between">
          <div class="gl-mr-5">{{ metric.title }}</div>
          <div class="gl-font-bold" data-testid="tooltip-value">{{ metric.value }}</div>
        </div>
      </div>
    </template>
  </gl-line-chart>
</template>
