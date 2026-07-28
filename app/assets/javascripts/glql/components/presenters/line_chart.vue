<script>
import DimensionRoutedChart from './chart/dimension_routed_chart.vue';
import SingleDimensionSeriesChart from './chart/single_dimension_series_chart.vue';

export default {
  name: 'LineChartPresenter',
  components: {
    DimensionRoutedChart,
    SingleDimensionSeriesChart,
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
};
</script>

<template>
  <dimension-routed-chart
    display-type="lineChart"
    :fields="fields"
    :loading="loading"
    :max-dimensions="1"
    @error="$emit('error', $event)"
  >
    <template #one-dimension="{ dimension, metrics }">
      <single-dimension-series-chart
        variant="line"
        :data="data"
        :dimension="dimension"
        :metrics="metrics"
      />
    </template>
  </dimension-routed-chart>
</template>
