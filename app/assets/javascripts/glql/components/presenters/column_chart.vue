<script>
import DimensionRoutedChart from './chart/dimension_routed_chart.vue';
import SingleDimensionColumnChart from './column_chart/single_dimension_column_chart.vue';
import TwoDimensionsColumnChart from './column_chart/two_dimensions_column_chart.vue';

export default {
  name: 'ColumnChartPresenter',
  components: {
    DimensionRoutedChart,
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
    maxSeries() {
      const maxSeries = Number(this.displayConfig.maxSeries);
      return Number.isInteger(maxSeries) && maxSeries > 0 ? maxSeries : null;
    },
  },
};
</script>

<template>
  <dimension-routed-chart
    display-type="columnChart"
    :fields="fields"
    :loading="loading"
    :display-config="displayConfig"
    @error="$emit('error', $event)"
  >
    <template #one-dimension="{ dimension, metrics, stacked }">
      <single-dimension-column-chart
        :data="data"
        :dimension="dimension"
        :metrics="metrics"
        :stacked="stacked"
      />
    </template>
    <template #two-dimensions="{ dimensions, metric }">
      <two-dimensions-column-chart
        :data="data"
        :primary-dimension="dimensions[0]"
        :secondary-dimension="dimensions[1]"
        :metric="metric"
        :max-series="maxSeries"
      />
    </template>
  </dimension-routed-chart>
</template>
