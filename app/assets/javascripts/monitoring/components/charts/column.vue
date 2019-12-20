<script>
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { debounceByAnimationFrame } from '~/lib/utils/common_utils';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import { chartHeight } from '../../constants';
import { makeDataSeries } from '~/helpers/monitor_helper';
import { graphDataValidatorForValues } from '../../utils';

export default {
  components: {
    GlColumnChart,
  },
  inheritAttrs: false,
  props: {
    graphData: {
      type: Object,
      required: true,
      validator: graphDataValidatorForValues.bind(null, false),
    },
    containerWidth: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      width: 0,
      height: chartHeight,
      svgs: {},
      debouncedResizeCallback: {},
    };
  },
  computed: {
    chartData() {
      const queryData = this.graphData.metrics.reduce((acc, query) => {
        const series = makeDataSeries(query.result || [], {
          name: this.formatLegendLabel(query),
        });

        return acc.concat(series);
      }, []);

      return {
        values: queryData[0].data,
      };
    },
    xAxisTitle() {
      return this.graphData.metrics[0].result[0].x_label !== undefined
        ? this.graphData.metrics[0].result[0].x_label
        : '';
    },
    yAxisTitle() {
      return this.graphData.metrics[0].result[0].y_label !== undefined
        ? this.graphData.metrics[0].result[0].y_label
        : '';
    },
    xAxisType() {
      return this.graphData.x_type !== undefined ? this.graphData.x_type : 'category';
    },
    dataZoomConfig() {
      const handleIcon = this.svgs['scroll-handle'];

      return handleIcon ? { handleIcon } : {};
    },
    chartOptions() {
      return {
        dataZoom: this.dataZoomConfig,
      };
    },
  },
  watch: {
    containerWidth: 'onResize',
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.debouncedResizeCallback);
  },
  created() {
    this.debouncedResizeCallback = debounceByAnimationFrame(this.onResize);
    window.addEventListener('resize', this.debouncedResizeCallback);
    this.setSvg('scroll-handle');
  },
  methods: {
    formatLegendLabel(query) {
      return `${query.label}`;
    },
    onResize() {
      const { width } = this.$refs.columnChart.$el.getBoundingClientRect();
      this.width = width;
    },
    setSvg(name) {
      getSvgIconPathContent(name)
        .then(path => {
          if (path) {
            this.$set(this.svgs, name, `path://${path}`);
          }
        })
        .catch(() => {});
    },
  },
};
</script>
<template>
  <div class="prometheus-graph">
    <div class="prometheus-graph-header">
      <h5 ref="graphTitle" class="prometheus-graph-title">{{ graphData.title }}</h5>
      <div ref="graphWidgets" class="prometheus-graph-widgets"><slot></slot></div>
    </div>
    <gl-column-chart
      ref="columnChart"
      v-bind="$attrs"
      :data="chartData"
      :option="chartOptions"
      :width="width"
      :height="height"
      :x-axis-title="xAxisTitle"
      :y-axis-title="yAxisTitle"
      :x-axis-type="xAxisType"
    />
  </div>
</template>
