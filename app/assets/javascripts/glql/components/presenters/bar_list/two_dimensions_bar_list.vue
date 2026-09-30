<script>
import { GlButton } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import BarListChart from '~/analytics/analytics_dashboards/components/visualizations/bar_list_chart.vue';
import { buildStackedByDimension, dimensionLabelFormatter } from '../../../utils/chart_data';
import { foldTail, pageOf } from './fold_tail';

const sum = (values) => values.reduce((total, value) => total + value, 0);

export default {
  name: 'TwoDimensionsBarList',
  components: {
    BarListChart,
    GlButton,
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
    pageSize: {
      required: true,
      type: Number,
    },
    page: {
      required: false,
      type: Number,
      default: 0,
    },
    maxSeries: {
      required: true,
      type: Number,
    },
  },
  data() {
    return {
      seriesExpanded: false,
    };
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

      return foldTail(ranked, this.seriesExpanded ? Infinity : this.maxSeries, (folded) => ({
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
    // Shares stay relative to the grand total across pages.
    rows() {
      return pageOf(this.allRows, this.page, this.pageSize);
    },
    // Mirrors foldTail's rule so the control appears only when a tail is
    // actually hidden, and stays put once it is expanded.
    canExpand() {
      return this.stacked.bars.length > this.maxSeries + 1;
    },
    toggleLabel() {
      return this.seriesExpanded
        ? s__('Glql|Show fewer')
        : sprintf(s__('Glql|Show all (%{count})'), { count: this.stacked.bars.length });
    },
  },
  watch: {
    // A new result set should not inherit the previous one's expanded state,
    // matching how the chart resets its hidden series.
    data() {
      this.seriesExpanded = false;
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
  <div>
    <bar-list-chart :data="rows" />
    <gl-button
      v-if="canExpand"
      category="tertiary"
      variant="link"
      size="small"
      class="gl-mb-3 gl-mt-4"
      :icon="seriesExpanded ? 'chevron-up' : 'chevron-down'"
      :aria-expanded="seriesExpanded.toString()"
      @click="seriesExpanded = !seriesExpanded"
    >
      {{ toggleLabel }}
    </gl-button>
  </div>
</template>
