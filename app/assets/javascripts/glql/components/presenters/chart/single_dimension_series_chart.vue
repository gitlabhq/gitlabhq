<script>
import { GlAreaChart, GlLineChart } from '@gitlab/ui/src/charts';
import {
  buildSeries,
  labelWithParameter,
  tooltipContentFromParams,
} from '../../../utils/chart_data';
import {
  buildFormatterByLabel,
  buildSharedAxisFormatter,
  formatValueForLabel,
  yAxisTitleFor,
} from '../../../utils/value_format';
import FormattedTooltipContent from './formatted_tooltip_content.vue';

const CHART_BY_VARIANT = {
  line: 'gl-line-chart',
  area: 'gl-area-chart',
};

const STACK_ID = 'metrics';

// Renders one series per metric over a single dimension, as lines or areas.
// Validating the dimension/metric combination is the owning presenter's job.
export default {
  name: 'SingleDimensionSeriesChart',
  components: {
    GlAreaChart,
    GlLineChart,
    FormattedTooltipContent,
  },
  props: {
    variant: {
      required: true,
      type: String,
      validator: (value) => Object.keys(CHART_BY_VARIANT).includes(value),
    },
    data: {
      required: true,
      type: Object,
    },
    dimension: {
      required: true,
      type: Object,
    },
    metrics: {
      required: true,
      type: Array,
    },
    stacked: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  computed: {
    chartComponent() {
      return CHART_BY_VARIANT[this.variant];
    },
    chartData() {
      const series = this.metrics.flatMap((m) => buildSeries(this.data.nodes, this.dimension, m));
      return this.stacked ? series.map((s) => ({ ...s, stack: STACK_ID })) : series;
    },
    formatterByLabel() {
      return buildFormatterByLabel(this.metrics);
    },
    sharedAxisFormatter() {
      return buildSharedAxisFormatter(this.metrics);
    },
    yAxisTitle() {
      return yAxisTitleFor(this.metrics);
    },
    chartOptions() {
      const options = {
        xAxis: { name: labelWithParameter(this.dimension) ?? '', type: 'category' },
      };
      const yAxis = {};
      if (this.yAxisTitle) {
        yAxis.name = this.yAxisTitle;
      }
      if (this.sharedAxisFormatter) {
        yAxis.axisLabel = { formatter: this.sharedAxisFormatter };
      }
      if (Object.keys(yAxis).length > 0) {
        options.yAxis = yAxis;
      }
      return options;
    },
  },
  methods: {
    formatValueByLabel(label, value) {
      return formatValueForLabel(this.formatterByLabel, label, value);
    },
    contentFromParams: tooltipContentFromParams,
  },
};
</script>

<template>
  <component
    :is="chartComponent"
    :data="chartData"
    :option="chartOptions"
    :include-legend-avg-max="false"
  >
    <template #tooltip-content="{ params }">
      <formatted-tooltip-content
        :content="contentFromParams(params)"
        :format-value="formatValueByLabel"
      />
    </template>
  </component>
</template>
