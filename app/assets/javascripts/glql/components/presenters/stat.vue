<script>
import { GlSingleStat } from '@gitlab/ui/src/charts';
import { GlSkeletonLoader } from '@gitlab/ui';
import { __ } from '~/locale';
import { dimensionsOf, metricsOf } from '../../utils/chart_data';
import { formatterFor } from '../../utils/value_format';

// Rendered when an aggregated query has no row for the single metric. Aggregations
// over an empty set can omit the node entirely, so distinguish "no data" from a 0.
const NO_VALUE = '—';

export default {
  name: 'StatPresenter',
  components: {
    GlSingleStat,
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
    validationError() {
      if (!this.fields.length) return null;
      if (this.metrics.length !== 1) {
        return __('stat display type requires exactly 1 metric');
      }
      if (this.dimensions.length > 0) {
        return __('stat display type cannot have dimensions');
      }
      return null;
    },
    metric() {
      return this.metrics[0];
    },
    displayValue() {
      if (!this.metric) return '';
      const value = this.data?.nodes?.[0]?.[this.metric.key];
      if (value == null) return NO_VALUE;
      return formatterFor(this.metric.key)(value);
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
    <gl-single-stat
      v-else-if="!validationError && metric"
      class="!gl-p-0"
      title=""
      :value="displayValue"
    />
  </div>
</template>
