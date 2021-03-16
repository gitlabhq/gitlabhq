<script>
import { GlChartSeriesLabel } from '@gitlab/ui/dist/charts';
import produce from 'immer';
import { flattenDeep, isNumber } from 'lodash';
import { hexToRgb } from '~/lib/utils/color_utils';
import { roundOffFloat } from '~/lib/utils/common_utils';
import { areaOpacityValues, symbolSizes, colorValues, panelTypes } from '../../constants';
import { graphDataValidatorForAnomalyValues } from '../../utils';
import MonitorTimeSeriesChart from './time_series.vue';

/**
 * Series indexes
 */
const METRIC = 0;
const UPPER = 1;
const LOWER = 2;

/**
 * Boundary area appearance
 */
const AREA_COLOR = colorValues.anomalyAreaColor;
const AREA_OPACITY = areaOpacityValues.default;
const AREA_COLOR_RGBA = `rgba(${hexToRgb(AREA_COLOR).join(',')},${AREA_OPACITY})`;

/**
 * The anomaly component highlights when a metric shows
 * some anomalous behavior.
 *
 * It shows both a metric line and a boundary band in a
 * time series chart, the boundary band shows the normal
 * range of values the metric should take.
 *
 * This component accepts 3 metrics, which contain the
 * "metric", "upper" limit and "lower" limit.
 *
 * The upper and lower series are "stacked areas" visually
 * to create the boundary band, and if any "metric" value
 * is outside this band, it is highlighted to warn users.
 *
 * The boundary band stack must be painted above the 0 line
 * so the area is shown correctly. If any of the values of
 * the data are negative, the chart data is shifted to be
 * above 0 line.
 *
 * The data passed to the time series is will always be
 * positive, but reformatted to show the original values of
 * data.
 *
 */
export default {
  components: {
    GlChartSeriesLabel,
    MonitorTimeSeriesChart,
  },
  inheritAttrs: false,
  props: {
    graphData: {
      type: Object,
      required: true,
      validator: graphDataValidatorForAnomalyValues,
    },
  },
  computed: {
    series() {
      return this.graphData.metrics.map((metric) => {
        const values = metric.result && metric.result[0] ? metric.result[0].values : [];
        return {
          label: metric.label,
          // NaN values may disrupt avg., max. & min. calculations in the legend, filter them out
          data: values.filter(([, value]) => !Number.isNaN(value)),
        };
      });
    },
    /**
     * If any of the values of the data is negative, the
     * chart data is shifted to the lowest value
     *
     * This offset is the lowest value.
     */
    yOffset() {
      const values = flattenDeep(this.series.map((ser) => ser.data.map(([, y]) => y)));
      const min = values.length ? Math.floor(Math.min(...values)) : 0;
      return min < 0 ? -min : 0;
    },
    metricData() {
      const originalMetricQuery = this.graphData.metrics[0];

      const metricQuery = produce(originalMetricQuery, (draftQuery) => {
        draftQuery.result[0].values = draftQuery.result[0].values.map(([x, y]) => [
          x,
          y + this.yOffset,
        ]);
      });
      return {
        ...this.graphData,
        type: panelTypes.LINE_CHART,
        metrics: [metricQuery],
      };
    },
    metricSeriesConfig() {
      return {
        type: 'line',
        symbol: 'circle',
        symbolSize: (val, params) => {
          if (this.isDatapointAnomaly(params.dataIndex)) {
            return symbolSizes.anomaly;
          }
          // 0 causes echarts to throw an error, use small number instead
          // see https://gitlab.com/gitlab-org/gitlab-ui/issues/423
          return 0.001;
        },
        showSymbol: true,
        itemStyle: {
          color: (params) => {
            if (this.isDatapointAnomaly(params.dataIndex)) {
              return colorValues.anomalySymbol;
            }
            return colorValues.primaryColor;
          },
        },
      };
    },
    chartOptions() {
      const [, upperSeries, lowerSeries] = this.series;
      const calcOffsetY = (data, offsetCallback) =>
        data.map((value, dataIndex) => {
          const [x, y] = value;
          return [x, y + offsetCallback(dataIndex)];
        });

      const yAxisWithOffset = {
        axisLabel: {
          formatter: (num) => roundOffFloat(num - this.yOffset, 3).toString(),
        },
      };

      /**
       * Boundary is rendered by 2 series: An invisible
       * series (opacity: 0) stacked on a visible one.
       *
       * Order is important, lower boundary is stacked
       * *below* the upper boundary.
       */
      const boundarySeries = [];

      if (upperSeries.data.length && lowerSeries.data.length) {
        // Lower boundary, plus the offset if negative values
        boundarySeries.push(
          this.makeBoundarySeries({
            name: this.formatLegendLabel(lowerSeries),
            data: calcOffsetY(lowerSeries.data, () => this.yOffset),
          }),
        );
        // Upper boundary, minus the lower boundary
        boundarySeries.push(
          this.makeBoundarySeries({
            name: this.formatLegendLabel(upperSeries),
            data: calcOffsetY(upperSeries.data, (i) => -this.yValue(LOWER, i)),
            areaStyle: {
              color: AREA_COLOR,
              opacity: AREA_OPACITY,
            },
          }),
        );
      }

      return { yAxis: yAxisWithOffset, series: boundarySeries };
    },
  },
  methods: {
    formatLegendLabel(query) {
      return query.label;
    },
    yValue(seriesIndex, dataIndex) {
      const d = this.series[seriesIndex].data[dataIndex];
      return d && d[1];
    },
    yValueFormatted(seriesIndex, dataIndex) {
      const y = this.yValue(seriesIndex, dataIndex);
      return isNumber(y) ? y.toFixed(3) : '';
    },
    isDatapointAnomaly(dataIndex) {
      const yVal = this.yValue(METRIC, dataIndex);
      const yUpper = this.yValue(UPPER, dataIndex);
      const yLower = this.yValue(LOWER, dataIndex);
      return (isNumber(yUpper) && yVal > yUpper) || (isNumber(yLower) && yVal < yLower);
    },
    makeBoundarySeries(series) {
      const stackKey = 'anomaly-boundary-series-stack';
      return {
        type: 'line',
        stack: stackKey,
        lineStyle: {
          width: 0,
          color: AREA_COLOR_RGBA, // legend color
        },
        color: AREA_COLOR_RGBA, // tooltip color
        symbol: 'none',
        ...series,
      };
    },
  },
};
</script>

<template>
  <monitor-time-series-chart
    v-bind="$attrs"
    :graph-data="metricData"
    :option="chartOptions"
    :series-config="metricSeriesConfig"
  >
    <slot></slot>
    <template #tooltip-content="slotProps">
      <div
        v-for="(content, seriesIndex) in slotProps.tooltip.content"
        :key="seriesIndex"
        class="d-flex justify-content-between"
      >
        <gl-chart-series-label :color="content.color">
          {{ content.name }}
        </gl-chart-series-label>
        <div class="gl-ml-7">
          {{ yValueFormatted(seriesIndex, content.dataIndex) }}
        </div>
      </div>
    </template>
  </monitor-time-series-chart>
</template>
