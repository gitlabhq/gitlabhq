<script>
import { GlResizeObserverDirective } from '@gitlab/ui';
import { GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import { chartHeight } from '../../constants';
import { graphDataValidatorForValues } from '../../utils';

export default {
  components: {
    GlStackedColumnChart,
  },
  directives: {
    GlResizeObserverDirective,
  },
  props: {
    graphData: {
      type: Object,
      required: true,
      validator: graphDataValidatorForValues.bind(null, false),
    },
  },
  data() {
    return {
      width: 0,
      height: chartHeight,
      svgs: {},
    };
  },
  computed: {
    chartData() {
      return this.graphData.metrics.map(metric => metric.result[0].values.map(val => val[1]));
    },
    xAxisTitle() {
      return this.graphData.x_label !== undefined ? this.graphData.x_label : '';
    },
    yAxisTitle() {
      return this.graphData.y_label !== undefined ? this.graphData.y_label : '';
    },
    xAxisType() {
      return this.graphData.x_type !== undefined ? this.graphData.x_type : 'category';
    },
    groupBy() {
      return this.graphData.metrics[0].result[0].values.map(val => val[0]);
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
    seriesNames() {
      return this.graphData.metrics.map(metric => metric.series_name);
    },
  },
  created() {
    this.setSvg('scroll-handle');
  },
  methods: {
    setSvg(name) {
      getSvgIconPathContent(name)
        .then(path => {
          if (path) {
            this.$set(this.svgs, name, `path://${path}`);
          }
        })
        .catch(e => {
          // eslint-disable-next-line no-console, @gitlab/i18n/no-non-i18n-strings
          console.error('SVG could not be rendered correctly: ', e);
        });
    },
    onResize() {
      if (!this.$refs.chart) return;
      const { width } = this.$refs.chart.$el.getBoundingClientRect();
      this.width = width;
    },
  },
};
</script>
<template>
  <div v-gl-resize-observer-directive="onResize" class="prometheus-graph">
    <div class="prometheus-graph-header">
      <h5 ref="graphTitle" class="prometheus-graph-title">{{ graphData.title }}</h5>
      <div ref="graphWidgets" class="prometheus-graph-widgets"><slot></slot></div>
    </div>
    <gl-stacked-column-chart
      ref="chart"
      v-bind="$attrs"
      :data="chartData"
      :option="chartOptions"
      :x-axis-title="xAxisTitle"
      :y-axis-title="yAxisTitle"
      :x-axis-type="xAxisType"
      :group-by="groupBy"
      :width="width"
      :height="height"
      :series-names="seriesNames"
    />
  </div>
</template>
