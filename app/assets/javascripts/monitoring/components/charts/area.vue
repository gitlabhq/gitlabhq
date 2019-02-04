<script>
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import dateFormat from 'dateformat';

export default {
  components: {
    GlAreaChart,
  },
  inheritAttrs: false,
  props: {
    graphData: {
      type: Object,
      required: true,
      validator(data) {
        return (
          data.queries &&
          Array.isArray(data.queries) &&
          data.queries.filter(query => {
            if (Array.isArray(query.result)) {
              return (
                query.result.filter(res => Array.isArray(res.values)).length === query.result.length
              );
            }
            return false;
          }).length === data.queries.length
        );
      },
    },
    alertData: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    chartData() {
      return this.graphData.queries.reduce((accumulator, query) => {
        accumulator[query.unit] = query.result.reduce((acc, res) => acc.concat(res.values), []);
        return accumulator;
      }, {});
    },
    chartOptions() {
      return {
        xAxis: {
          name: 'Time',
          type: 'time',
          axisLabel: {
            formatter: date => dateFormat(date, 'h:MM TT'),
          },
          axisPointer: {
            snap: true,
          },
          nameTextStyle: {
            padding: [18, 0, 0, 0],
          },
        },
        yAxis: {
          name: this.yAxisLabel,
          axisLabel: {
            formatter: value => value.toFixed(3),
          },
          nameTextStyle: {
            padding: [0, 0, 36, 0],
          },
        },
        legend: {
          formatter: this.xAxisLabel,
        },
      };
    },
    xAxisLabel() {
      return this.graphData.queries.map(query => query.label).join(', ');
    },
    yAxisLabel() {
      const [query] = this.graphData.queries;
      return `${this.graphData.y_label} (${query.unit})`;
    },
  },
  methods: {
    formatTooltipText(params) {
      const [date, value] = params;
      return [dateFormat(date, 'dd mmm yyyy, h:MMtt'), value.toFixed(3)];
    },
  },
};
</script>

<template>
  <div class="prometheus-graph col-12 col-lg-6">
    <div class="prometheus-graph-header">
      <h5 class="prometheus-graph-title">{{ graphData.title }}</h5>
      <div class="prometheus-graph-widgets"><slot></slot></div>
    </div>
    <gl-area-chart
      v-bind="$attrs"
      :data="chartData"
      :option="chartOptions"
      :format-tooltip-text="formatTooltipText"
      :thresholds="alertData"
    />
  </div>
</template>
