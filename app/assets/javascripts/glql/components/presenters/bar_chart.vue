<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { dimensionsOf, metricsOf } from '../../utils/chart_data';
import { dimensionMetricValidationError } from '../../utils/chart_validation';
import SingleDimensionBarChart from './bar_chart/single_dimension_bar_chart.vue';
import TwoDimensionsBarChart from './bar_chart/two_dimensions_bar_chart.vue';

export default {
  name: 'BarChartPresenter',
  components: {
    GlSkeletonLoader,
    SingleDimensionBarChart,
    TwoDimensionsBarChart,
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
    displayConfig: {
      required: false,
      type: Object,
      default: () => ({}),
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
      return dimensionMetricValidationError({
        displayType: 'barChart',
        dimensions: this.dimensions,
        metrics: this.metrics,
      });
    },
    stacked() {
      return this.displayConfig?.stacked === true;
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
    <template v-else-if="!validationError">
      <single-dimension-bar-chart
        v-if="dimensions.length === 1"
        :data="data"
        :dimension="dimensions[0]"
        :metrics="metrics"
        :stacked="stacked"
      />
      <two-dimensions-bar-chart
        v-else-if="dimensions.length === 2"
        :data="data"
        :primary-dimension="dimensions[0]"
        :secondary-dimension="dimensions[1]"
        :metric="metrics[0]"
      />
    </template>
  </div>
</template>
