<script>
import { GlResizeObserverDirective } from '@gitlab/ui';
import { GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import { chartHeight, legendLayoutTypes } from '../../constants';
import { s__ } from '~/locale';
import { graphDataValidatorForValues } from '../../utils';
import { getTimeAxisOptions, axisTypes } from './options';
import { formats, timezones } from '../../format_date';

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
    timezone: {
      type: String,
      required: false,
      default: timezones.LOCAL,
    },
    legendLayout: {
      type: String,
      required: false,
      default: legendLayoutTypes.table,
    },
    legendAverageText: {
      type: String,
      required: false,
      default: s__('Metrics|Avg'),
    },
    legendCurrentText: {
      type: String,
      required: false,
      default: s__('Metrics|Current'),
    },
    legendMaxText: {
      type: String,
      required: false,
      default: s__('Metrics|Max'),
    },
    legendMinText: {
      type: String,
      required: false,
      default: s__('Metrics|Min'),
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
      return this.graphData.metrics
        .map(({ label: name, result }) => {
          // This needs a fix. Not only metrics[0] should be shown.
          // See https://gitlab.com/gitlab-org/gitlab/-/issues/220492
          if (!result || result.length === 0) {
            return [];
          }
          return { name, data: result[0].values.map(val => val[1]) };
        })
        .slice(0, 1);
    },
    xAxisTitle() {
      return this.graphData.x_label !== undefined ? this.graphData.x_label : '';
    },
    yAxisTitle() {
      return this.graphData.y_label !== undefined ? this.graphData.y_label : '';
    },
    xAxisType() {
      // stacked-column component requires the x-axis to be of type `category`
      return axisTypes.category;
    },
    groupBy() {
      // This needs a fix. Not only metrics[0] should be shown.
      // See https://gitlab.com/gitlab-org/gitlab/-/issues/220492
      const { result } = this.graphData.metrics[0];
      if (!result || result.length === 0) {
        return [];
      }
      return result[0].values.map(val => val[0]);
    },
    dataZoomConfig() {
      const handleIcon = this.svgs['scroll-handle'];

      return handleIcon ? { handleIcon } : {};
    },
    chartOptions() {
      return {
        xAxis: {
          ...getTimeAxisOptions({ timezone: this.timezone, format: formats.shortTime }),
          type: this.xAxisType,
        },
        dataZoom: [this.dataZoomConfig],
      };
    },
    seriesNames() {
      return this.graphData.metrics.map(metric => metric.label);
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
          // eslint-disable-next-line no-console, @gitlab/require-i18n-strings
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
  <div v-gl-resize-observer-directive="onResize">
    <gl-stacked-column-chart
      ref="chart"
      v-bind="$attrs"
      :bars="chartData"
      :option="chartOptions"
      :x-axis-title="xAxisTitle"
      :y-axis-title="yAxisTitle"
      :x-axis-type="xAxisType"
      :group-by="groupBy"
      :width="width"
      :height="height"
      :legend-layout="legendLayout"
      :legend-average-text="legendAverageText"
      :legend-current-text="legendCurrentText"
      :legend-max-text="legendMaxText"
      :legend-min-text="legendMinText"
    />
  </div>
</template>
