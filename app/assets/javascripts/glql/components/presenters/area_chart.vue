<script>
import TwoDimensionsAreaChart from './area_chart/two_dimensions_area_chart.vue';
import DimensionRoutedChart from './chart/dimension_routed_chart.vue';
import SingleDimensionSeriesChart from './chart/single_dimension_series_chart.vue';

export default {
  name: 'AreaChartPresenter',
  components: {
    DimensionRoutedChart,
    SingleDimensionSeriesChart,
    TwoDimensionsAreaChart,
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
    stacked() {
      return this.displayConfig?.stacked === true;
    },
  },
};
</script>

<template>
  <dimension-routed-chart
    display-type="areaChart"
    :fields="fields"
    :loading="loading"
    @error="$emit('error', $event)"
  >
    <template #one-dimension="{ dimension, metrics }">
      <single-dimension-series-chart
        variant="area"
        :data="data"
        :dimension="dimension"
        :metrics="metrics"
        :stacked="stacked"
      />
    </template>
    <template #two-dimensions="{ dimensions, metric }">
      <two-dimensions-area-chart
        :data="data"
        :primary-dimension="dimensions[0]"
        :secondary-dimension="dimensions[1]"
        :metric="metric"
      />
    </template>
  </dimension-routed-chart>
</template>
