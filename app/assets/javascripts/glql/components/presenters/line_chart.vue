<script>
import { GlLineChart } from '@gitlab/ui/src/charts';
import { GlSkeletonLoader } from '@gitlab/ui';
import { __ } from '~/locale';
import {
  buildSeries,
  dimensionsOf,
  metricsOf,
  tooltipContentFromParams,
} from '../../utils/chart_data';
import {
  buildFormatterByLabel,
  buildSharedAxisFormatter,
  formatValueForLabel,
  yAxisTitleFor,
} from '../../utils/value_format';
import FormattedTooltipContent from './chart/formatted_tooltip_content.vue';

export default {
  name: 'LineChartPresenter',
  components: {
    GlLineChart,
    GlSkeletonLoader,
    FormattedTooltipContent,
  },
  props: {
    data: {
      required: false,
      type: Object,
      default: () => ({ nodes: [] }),
    },
    fields: {
      required: false,
      type: Array,
      default: () => [],
    },
    loading: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  emits: { error: null },
  computed: {
    dimensions() {
      return dimensionsOf(this.fields);
    },
    metrics() {
      return metricsOf(this.fields);
    },
    validationError() {
      if (!this.fields.length) return null;
      if (this.dimensions.length === 0) {
        return __('lineChart requires at least one dimension');
      }
      if (this.dimensions.length > 1) {
        return __('lineChart supports exactly one dimension');
      }
      if (this.metrics.length === 0) {
        return __('lineChart requires at least one metric');
      }
      return null;
    },
    dimension() {
      return this.dimensions[0];
    },
    chartData() {
      return this.metrics.flatMap((m) => buildSeries(this.data.nodes, this.dimension, m));
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
        xAxis: { name: this.dimension?.label ?? '', type: 'category' },
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
  watch: {
    validationError: {
      immediate: true,
      handler(message) {
        if (message) this.$emit('error', new Error(message));
      },
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
  <div>
    <gl-skeleton-loader v-if="loading" />
    <gl-line-chart
      v-else-if="!validationError && dimension"
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
    </gl-line-chart>
  </div>
</template>
