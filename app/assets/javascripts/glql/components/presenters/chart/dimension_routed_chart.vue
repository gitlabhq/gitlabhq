<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { dimensionsOf, metricsOf } from '../../../utils/chart_data';
import { dimensionMetricValidationError } from '../../../utils/chart_validation';

// Shared shell for the chart display types that plot dimensions against
// metrics (column, bar, line, area). Owns the wiring each of them would
// otherwise repeat: the loading skeleton, dimension/metric validation
// (emitted as `error` for the embedded-view alert), and routing on dimension
// count. The owning presenter supplies the actual chart through the
// `one-dimension` / `two-dimensions` scoped slots.
export default {
  name: 'DimensionRoutedChart',
  components: {
    GlSkeletonLoader,
  },
  props: {
    displayType: {
      required: true,
      type: String,
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
    maxDimensions: {
      required: false,
      type: Number,
      default: 2,
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
        displayType: this.displayType,
        dimensions: this.dimensions,
        metrics: this.metrics,
        maxDimensions: this.maxDimensions,
      });
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
      <slot
        v-if="dimensions.length === 1"
        name="one-dimension"
        :dimension="dimensions[0]"
        :metrics="metrics"
      ></slot>
      <slot
        v-else-if="dimensions.length === 2"
        name="two-dimensions"
        :dimensions="dimensions"
        :metric="metrics[0]"
      ></slot>
    </template>
  </div>
</template>
