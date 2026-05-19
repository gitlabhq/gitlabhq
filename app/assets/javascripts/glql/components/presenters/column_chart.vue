<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { __ } from '~/locale';
import { dimensionsOf, metricsOf } from '../../utils/chart_data';
import SingleDimensionColumnChart from './column_chart/single_dimension_column_chart.vue';
import TwoDimensionsColumnChart from './column_chart/two_dimensions_column_chart.vue';

export default {
  name: 'ColumnChartPresenter',
  components: {
    GlSkeletonLoader,
    SingleDimensionColumnChart,
    TwoDimensionsColumnChart,
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
      if (this.dimensions.length === 0) {
        return __('columnChart requires at least one dimension');
      }
      if (this.dimensions.length > 2) {
        return __('columnChart supports a maximum of 2 dimensions');
      }
      if (this.metrics.length === 0) {
        return __('columnChart requires at least one metric');
      }
      if (this.dimensions.length === 2 && this.metrics.length > 1) {
        return __('columnChart with 2 dimensions supports only a single metric');
      }
      return null;
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
  <div class="gl-px-5 gl-py-5">
    <gl-skeleton-loader v-if="loading" />
    <template v-else-if="!validationError">
      <single-dimension-column-chart
        v-if="dimensions.length === 1"
        :data="data"
        :dimension="dimensions[0]"
        :metrics="metrics"
        :stacked="stacked"
      />
      <two-dimensions-column-chart
        v-else-if="dimensions.length === 2"
        :data="data"
        :primary-dimension="dimensions[0]"
        :secondary-dimension="dimensions[1]"
        :metric="metrics[0]"
      />
    </template>
  </div>
</template>
