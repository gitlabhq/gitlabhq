<script>
import { GlStackedColumnChart, GlColumnChart } from '@gitlab/ui/src/charts';
import { GlSkeletonLoader } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';
import { __ } from '~/locale';

export default {
  components: {
    GlStackedColumnChart,
    GlColumnChart,
    GlSkeletonLoader,
  },
  props: {
    data: {
      required: false,
      type: Object,
      default: () => ({ nodes: [] }),
    },
    loading: {
      required: false,
      type: [Boolean, Number],
      default: false,
    },
    aggregate: {
      required: false,
      type: Array,
      default: null,
    },
    groupBy: {
      required: false,
      type: Array,
      default: null,
    },
  },
  computed: {
    primaryMetric() {
      if (!this.aggregate) return null;

      return this.aggregate[0];
    },
    primaryDimension() {
      if (!this.groupBy) return null;

      return this.groupBy[0];
    },
    secondaryDimension() {
      if (!this.groupBy) return null;

      return this.groupBy[1];
    },
    secondaryMetric() {
      if (!this.aggregate) return null;

      return this.aggregate[1];
    },
    primaryChartData() {
      return this.chartData(this.primaryMetric);
    },
    secondaryChartData() {
      return this.chartData(this.secondaryMetric);
    },
    chartOptions() {
      if (!this.primaryDimension || !this.primaryMetric) return {};

      return {
        xAxis: {
          type: 'category',
          name: this.primaryDimension.field.label,
        },
        yAxis: {
          name: this.primaryMetric.label,
          axisLabel: {
            formatter: '{value}',
          },
        },
      };
    },
    primaryStackedChartData() {
      return this.stackedChartData(this.primaryMetric);
    },
    secondaryStackedChartData() {
      return this.stackedChartData(this.secondaryMetric).bars;
    },
    groups() {
      return this.primaryStackedChartData.groups;
    },
    bars() {
      return this.primaryStackedChartData.bars;
    },
  },
  methods: {
    dimensionValue(datapoint, dimension) {
      const data = datapoint[dimension.field.key];
      if (dimension.fn.type === 'time') {
        const { unit } = dimension.fn;
        // TODO handle unit > 1. Need to somehow show 'from x to y'
        const fromDate = new Date(data.range.from).getTime();
        switch (unit) {
          case 'd': // day
            return formatDate(fromDate, 'yyyy-mm-dd');
          case 'w': // week
            return formatDate(fromDate, 'yyyy-mm-dd');
          case 'm': // month
            return formatDate(fromDate, 'mmm yy');
          case 'y': // year
            return formatDate(fromDate, 'yyyy');
          default:
            break;
        }
      }
      if (dimension.fn.type === 'user') {
        return data.user.value;
      }
      return __('Unknown');
    },
    chartData(metric) {
      if (!this.data.nodes?.length || !this.primaryDimension || !metric) return [];

      return [
        {
          name: metric.label,
          data: this.data.nodes.map((node) => [
            this.dimensionValue(node, this.primaryDimension),
            node[metric.key] || 0,
          ]),
        },
      ];
    },
    stackedChartData(metric) {
      if (
        !this.data.nodes?.length ||
        !this.primaryDimension ||
        !this.secondaryDimension ||
        !metric
      ) {
        return { groups: [], bars: [] };
      }

      const groups = [];
      const bars = {};

      this.data.nodes.forEach((node) => {
        const primaryDimensionValue = this.dimensionValue(node, this.primaryDimension);
        const secondaryDimensionValue = this.dimensionValue(node, this.secondaryDimension);

        if (groups.indexOf(primaryDimensionValue) === -1) {
          groups.push(primaryDimensionValue);
        }

        if (!bars[secondaryDimensionValue]) {
          bars[secondaryDimensionValue] = [];
        }

        bars[secondaryDimensionValue].push(node[metric.key] || 0);
      });

      return {
        groups,
        bars: Object.entries(bars).map(([key, val]) => ({ name: key, data: val })),
      };
    },
  },
};
</script>

<template>
  <div class="gl-px-5 gl-py-5">
    <gl-skeleton-loader v-if="loading" />
    <template v-else-if="primaryDimension && primaryMetric">
      <gl-column-chart
        v-if="groupBy.length === 1"
        :bars="primaryChartData"
        :option="chartOptions"
        x-axis-type="category"
        :x-axis-title="primaryDimension.field.label"
        :y-axis-title="primaryMetric.label"
        :secondary-data="secondaryChartData"
        :secondary-data-title="secondaryMetric && secondaryMetric.label"
      />
      <gl-stacked-column-chart
        v-else-if="groupBy.length === 2"
        x-axis-type="category"
        :x-axis-title="primaryDimension.field.label"
        :y-axis-title="primaryMetric.label"
        :group-by="groups"
        :presentation="secondaryMetric ? 'stacked' : 'tiled'"
        :bars="bars"
        :secondary-data="secondaryStackedChartData"
        :secondary-data-title="secondaryMetric && secondaryMetric.label"
        :include-legend-avg-max="false"
      />
    </template>
  </div>
</template>
