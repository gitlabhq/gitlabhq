<script>
import { GlResizeObserverDirective } from '@gitlab/ui';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { makeDataSeries } from '~/helpers/monitor_helper';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import { chartHeight } from '../../constants';
import { timezones } from '../../format_date';
import { graphDataValidatorForValues } from '../../utils';
import { getTimeAxisOptions, getYAxisOptions, getChartGrid } from './options';

export default {
  components: {
    GlColumnChart,
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
  },
  data() {
    return {
      width: 0,
      height: chartHeight,
      svgs: {},
    };
  },
  computed: {
    barChartData() {
      return this.graphData.metrics.reduce((acc, query) => {
        const series = makeDataSeries(query.result || [], {
          name: this.formatLegendLabel(query),
        });

        return acc.concat(series);
      }, []);
    },
    chartOptions() {
      const xAxis = getTimeAxisOptions({ timezone: this.timezone });

      const yAxis = {
        ...getYAxisOptions(this.graphData.yAxis),
        scale: false,
      };

      return {
        grid: getChartGrid(),
        xAxis,
        yAxis,
        dataZoom: [this.dataZoomConfig],
      };
    },
    xAxisTitle() {
      return this.graphData.metrics[0].result[0].x_label !== undefined
        ? this.graphData.metrics[0].result[0].x_label
        : '';
    },
    yAxisTitle() {
      return this.chartOptions.yAxis.name;
    },
    xAxisType() {
      return this.graphData.x_type !== undefined ? this.graphData.x_type : 'category';
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
    onResize() {
      if (!this.$refs.columnChart) return;
      const { width } = this.$refs.columnChart.$el.getBoundingClientRect();
      this.width = width;
    },
    setSvg(name) {
      getSvgIconPathContent(name)
        .then((path) => {
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
  <div v-gl-resize-observer-directive="onResize">
    <gl-column-chart
      ref="columnChart"
      v-bind="$attrs"
      :bars="barChartData"
      :option="chartOptions"
      :width="width"
      :height="height"
      :x-axis-title="xAxisTitle"
      :y-axis-title="yAxisTitle"
      :x-axis-type="xAxisType"
    />
  </div>
</template>
