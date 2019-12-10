<script>
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import dateFormat from 'dateformat';
import { debounceByAnimationFrame } from '~/lib/utils/common_utils';
import { X_INTERVAL } from '../constants';
import { validateGraphData } from '../utils';
import { __ } from '~/locale';

let debouncedResize;

export default {
  components: {
    GlAreaChart,
  },
  inheritAttrs: false,
  props: {
    graphData: {
      type: Object,
      required: true,
      validator: validateGraphData,
    },
    containerWidth: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      tooltipPopoverTitle: '',
      tooltipPopoverContent: '',
      width: this.containerWidth,
    };
  },
  computed: {
    chartData() {
      return this.graphData.queries.reduce((accumulator, query) => {
        accumulator[query.unit] = query.result.reduce((acc, res) => acc.concat(res.values), []);
        return accumulator;
      }, {});
    },
    extractTimeData() {
      return this.chartData.requests.map(data => data.time);
    },
    generateSeries() {
      return {
        name: __('Invocations'),
        type: 'line',
        data: this.chartData.requests.map(data => [data.time, data.value]),
        symbolSize: 0,
      };
    },
    getInterval() {
      const { result } = this.graphData.queries[0];

      if (result.length === 0) {
        return 1;
      }

      const split = result[0].values.reduce(
        (acc, pair) => (pair.value > acc ? pair.value : acc),
        1,
      );

      return split < X_INTERVAL ? split : X_INTERVAL;
    },
    chartOptions() {
      return {
        xAxis: {
          name: 'time',
          type: 'time',
          axisLabel: {
            formatter: date => dateFormat(date, 'h:MM TT'),
          },
          data: this.extractTimeData,
          nameTextStyle: {
            padding: [18, 0, 0, 0],
          },
        },
        yAxis: {
          name: this.yAxisLabel,
          nameTextStyle: {
            padding: [0, 0, 36, 0],
          },
          splitNumber: this.getInterval,
        },
        legend: {
          formatter: this.xAxisLabel,
        },
        series: this.generateSeries,
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
  watch: {
    containerWidth: 'onResize',
  },
  beforeDestroy() {
    window.removeEventListener('resize', debouncedResize);
  },
  created() {
    debouncedResize = debounceByAnimationFrame(this.onResize);
    window.addEventListener('resize', debouncedResize);
  },
  methods: {
    formatTooltipText(params) {
      const [seriesData] = params.seriesData;
      this.tooltipPopoverTitle = dateFormat(params.value, 'dd mmm yyyy, h:MMTT');
      this.tooltipPopoverContent = `${this.yAxisLabel}: ${seriesData.value[1]}`;
    },
    onResize() {
      const { width } = this.$refs.areaChart.$el.getBoundingClientRect();
      this.width = width;
    },
  },
};
</script>

<template>
  <div class="prometheus-graph">
    <div class="prometheus-graph-header">
      <h5 ref="graphTitle" class="prometheus-graph-title">{{ graphData.title }}</h5>
      <div ref="graphWidgets" class="prometheus-graph-widgets">
        <slot></slot>
      </div>
    </div>
    <gl-area-chart
      ref="areaChart"
      v-bind="$attrs"
      :data="[]"
      :option="chartOptions"
      :format-tooltip-text="formatTooltipText"
      :width="width"
      :include-legend-avg-max="false"
    >
      <template slot="tooltipTitle">{{ tooltipPopoverTitle }}</template>
      <template slot="tooltipContent">{{ tooltipPopoverContent }}</template>
    </gl-area-chart>
  </div>
</template>
