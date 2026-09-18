<script>
import { s__, sprintf } from '~/locale';
import BarListChart from '~/analytics/analytics_dashboards/components/visualizations/bar_list_chart.vue';
import { buildStackedByDimension, dimensionLabelFormatter } from '../../../utils/chart_data';
import { foldTail } from './fold_tail';

const sum = (values) => values.reduce((total, value) => total + value, 0);

export default {
  name: 'TwoDimensionsBarList',
  components: {
    BarListChart,
  },
  props: {
    data: {
      required: true,
      type: Object,
    },
    primaryDimension: {
      required: true,
      type: Object,
    },
    secondaryDimension: {
      required: true,
      type: Object,
    },
    metric: {
      required: true,
      type: Object,
    },
    maxRows: {
      required: true,
      type: Number,
    },
    maxSeries: {
      required: true,
      type: Number,
    },
  },
  computed: {
    stacked() {
      return buildStackedByDimension({
        nodes: this.data.nodes,
        primaryDim: this.primaryDimension,
        secondaryDim: this.secondaryDimension,
        metric: this.metric,
      });
    },
    // One stacked segment per secondary value, ranked by total; values beyond
    // the maxSeries biggest fold into an Other segment.
    series() {
      const ranked = [...this.stacked.bars].sort((a, b) => sum(b.data) - sum(a.data));

      return foldTail(ranked, this.maxSeries, (folded) => ({
        name: sprintf(s__('Glql|Other (%{count})'), { count: folded.length }),
        data: this.stacked.groups.map((_, index) => sum(folded.map((bar) => bar.data[index] ?? 0))),
      }));
    },
    grandTotal() {
      return sum(this.series.map((bar) => sum(bar.data)));
    },
    // Every row, sorted by value descending, with shares of the grand total.
    allRows() {
      const formatPrimary = dimensionLabelFormatter(this.data.nodes, this.primaryDimension);

      return this.stacked.groups
        .map((group, index) => {
          const segments = this.series.map((bar) => {
            const value = bar.data[index] ?? 0;
            return { name: bar.name, value, share: this.shareOf(value) };
          });
          const value = sum(segments.map((segment) => segment.value));

          return { name: formatPrimary(group), value, share: this.shareOf(value), segments };
        })
        .sort((a, b) => b.value - a.value);
    },
    // Rows past maxRows fold into one Other row, mirroring the one-dimension
    // path, so bars always sum to 100% of the grand total.
    rows() {
      return foldTail(this.allRows, this.maxRows, (folded) => {
        const segments = this.series.map((bar, index) => {
          const value = sum(folded.map((row) => row.segments[index]?.value ?? 0));
          return { name: bar.name, value, share: this.shareOf(value) };
        });
        const value = sum(segments.map((segment) => segment.value));

        return {
          name: sprintf(s__('Glql|Other (%{count})'), { count: folded.length }),
          value,
          share: this.shareOf(value),
          segments,
        };
      });
    },
  },
  methods: {
    shareOf(value) {
      return this.grandTotal ? (value / this.grandTotal) * 100 : 0;
    },
  },
};
</script>
<template>
  <bar-list-chart :data="rows" />
</template>
