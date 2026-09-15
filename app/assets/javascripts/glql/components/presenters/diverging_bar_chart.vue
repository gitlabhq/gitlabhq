<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import DivergingBarChart from '~/analytics/analytics_dashboards/components/visualizations/diverging_bar_chart.vue';
import { __ } from '~/locale';
import {
  dimensionsOf,
  metricsOf,
  dimensionValue,
  dimensionLabelFormatter,
  labelWithParameter,
  baseFieldKeyOf,
} from '../../utils/chart_data';
import { axisFormatterFor, formatCountCompact, unitFor } from '../../utils/value_format';

// The two halves are a pair, so the type takes exactly two metrics rather than
// the "one or more" the shared shell validates.
const SERIES_COUNT = 2;

// Counts render thousands as a lowercase `k`, matching the bar list on the same
// dashboard. Other units keep their own axis formatter.
const valueFormatterFor = (metric) => {
  const fieldKey = baseFieldKeyOf(metric);

  return unitFor(fieldKey) === 'count'
    ? (value) => formatCountCompact(value, { lowercaseThousands: true })
    : axisFormatterFor(fieldKey);
};

export default {
  name: 'DivergingBarChartPresenter',
  components: {
    DivergingBarChart,
    GlSkeletonLoader,
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
    dimension() {
      return this.dimensions[0];
    },
    nodes() {
      return this.data?.nodes ?? [];
    },
    // Fields arrive after the first render, and an empty set is not yet an
    // error, so the chart waits for a complete pair rather than drawing one
    // half of itself.
    hasSeries() {
      return Boolean(this.dimension) && this.metrics.length === SERIES_COUNT;
    },
    validationError() {
      if (!this.fields.length) return null;
      if (this.dimensions.length !== 1) {
        return __('divergingBarChart display type requires exactly 1 dimension');
      }
      if (this.metrics.length !== SERIES_COUNT) {
        return __('divergingBarChart display type requires exactly 2 metrics');
      }
      return null;
    },
    rows() {
      if (this.validationError || !this.dimension) return [];

      const formatLabel = dimensionLabelFormatter(this.nodes, this.dimension);

      return this.nodes.map((node) => ({
        name: formatLabel(dimensionValue(node, this.dimension)),
        values: this.metrics.map((metric) => node[metric.key] ?? 0),
      }));
    },
    seriesNames() {
      return this.metrics.map((metric) => labelWithParameter(metric));
    },
    valueFormatters() {
      return this.metrics.map(valueFormatterFor);
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
};
</script>

<template>
  <div>
    <gl-skeleton-loader v-if="loading" />
    <diverging-bar-chart
      v-else-if="!validationError && hasSeries"
      :data="rows"
      :series-names="seriesNames"
      :value-formatters="valueFormatters"
    />
  </div>
</template>
