<script>
import { GlBarChart } from '@gitlab/ui/dist/charts';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import { chartHeight } from '../../constants';
import { barChartsDataParser, graphDataValidatorForValues } from '../../utils';

export default {
  components: {
    GlBarChart,
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
      return barChartsDataParser(this.graphData.metrics);
    },
    chartOptions() {
      return {
        dataZoom: [this.dataZoomConfig],
      };
    },
    xAxisTitle() {
      const { xLabel = '' } = this.graphData;
      return xLabel;
    },
    yAxisTitle() {
      const { y_label: yLabel = '' } = this.graphData;
      return yLabel;
    },
    xAxisType() {
      const { x_type: xType = 'value' } = this.graphData;
      return xType;
    },
    dataZoomConfig() {
      const handleIcon = this.svgs['scroll-handle'];

      return handleIcon ? { handleIcon } : {};
    },
  },
  created() {
    this.setSvg('scroll-handle');
  },
  methods: {
    formatLegendLabel(query) {
      return query.label;
    },
    setSvg(name) {
      getSvgIconPathContent(name)
        .then((path) => {
          if (path) {
            this.$set(this.svgs, name, `path://${path}`);
          }
        })
        .catch((e) => {
          // eslint-disable-next-line no-console, @gitlab/require-i18n-strings
          console.error('SVG could not be rendered correctly: ', e);
        });
    },
  },
};
</script>
<template>
  <gl-bar-chart
    ref="barChart"
    v-bind="$attrs"
    :responsive="true"
    :data="chartData"
    :option="chartOptions"
    :width="width"
    :height="height"
    :x-axis-title="xAxisTitle"
    :y-axis-title="yAxisTitle"
    :x-axis-type="xAxisType"
  />
</template>
