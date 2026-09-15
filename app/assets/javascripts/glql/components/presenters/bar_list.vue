<script>
import { s__, sprintf } from '~/locale';
import BarListChart from '~/analytics/analytics_dashboards/components/visualizations/bar_list_chart.vue';
import { dimensionValue, dimensionLabelFormatter } from '../../utils/chart_data';
import DimensionRoutedChart from './chart/dimension_routed_chart.vue';

// Six rows plus a rolled-up Other row, which is the shape of the design this
// display type was built for. A query returning fewer rows is unaffected.
const DEFAULT_MAX_ROWS = 6;

export default {
  name: 'BarListPresenter',
  components: {
    BarListChart,
    DimensionRoutedChart,
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
    maxRows() {
      const maxRows = Number(this.displayConfig.maxRows);
      return Number.isInteger(maxRows) && maxRows > 0 ? maxRows : DEFAULT_MAX_ROWS;
    },
  },
  methods: {
    // Share is each row's % of the grand total rather than of the largest row
    rowsFor(dimension, metric) {
      const nodes = this.data?.nodes ?? [];
      const formatLabel = dimensionLabelFormatter(nodes, dimension);

      const rows = nodes.map((node) => ({
        name: formatLabel(dimensionValue(node, dimension)),
        value: node[metric.key] ?? 0,
      }));
      const total = rows.reduce((sum, { value }) => sum + value, 0);
      const shareOf = (value) => (total ? (value / total) * 100 : 0);
      const descending = rows.sort((a, b) => b.value - a.value);

      if (descending.length <= this.maxRows + 1) {
        return descending.map((row) => ({ ...row, share: shareOf(row.value) }));
      }

      const remainder = descending.slice(this.maxRows);
      const remainderValue = remainder.reduce((sum, { value }) => sum + value, 0);

      return [
        ...descending.slice(0, this.maxRows).map((row) => ({ ...row, share: shareOf(row.value) })),
        {
          name: sprintf(s__('Glql|Other (%{count})'), { count: remainder.length }),
          value: remainderValue,
          share: shareOf(remainderValue),
        },
      ];
    },
  },
};
</script>

<template>
  <dimension-routed-chart
    display-type="barList"
    :fields="fields"
    :loading="loading"
    :max-dimensions="1"
    @error="$emit('error', $event)"
  >
    <template #one-dimension="{ dimension, metrics }">
      <bar-list-chart :data="rowsFor(dimension, metrics[0])" />
    </template>
  </dimension-routed-chart>
</template>
