<script>
import SingleDimensionBarChart from './bar_chart/single_dimension_bar_chart.vue';
import TwoDimensionsBarChart from './bar_chart/two_dimensions_bar_chart.vue';
import DimensionRoutedChart from './chart/dimension_routed_chart.vue';
import {
  CATEGORY_LABELS_VALUE_AND_SHARE,
  COLOR_BY_OPTIONS,
  COLOR_BY_SERIES,
} from './bar_chart/bar_chart_options';

export default {
  name: 'BarChartPresenter',
  components: {
    DimensionRoutedChart,
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
    stacked() {
      return this.displayConfig?.stacked === true;
    },
    shareLabels() {
      return this.displayConfig?.categoryLabels === CATEGORY_LABELS_VALUE_AND_SHARE;
    },
    showAxisTitles() {
      return this.displayConfig?.showAxisTitles !== false;
    },
    colorBy() {
      const value = this.displayConfig?.colorBy;
      return COLOR_BY_OPTIONS.includes(value) ? value : COLOR_BY_SERIES;
    },
  },
};
</script>

<template>
  <dimension-routed-chart
    display-type="barChart"
    :fields="fields"
    :loading="loading"
    @error="$emit('error', $event)"
  >
    <template #one-dimension="{ dimension, metrics }">
      <single-dimension-bar-chart
        :data="data"
        :dimension="dimension"
        :metrics="metrics"
        :stacked="stacked"
        :share-labels="shareLabels"
        :show-axis-titles="showAxisTitles"
        :color-by="colorBy"
      />
    </template>
    <template #two-dimensions="{ dimensions, metric }">
      <two-dimensions-bar-chart
        :data="data"
        :primary-dimension="dimensions[0]"
        :secondary-dimension="dimensions[1]"
        :metric="metric"
        :show-axis-titles="showAxisTitles"
      />
    </template>
  </dimension-routed-chart>
</template>
