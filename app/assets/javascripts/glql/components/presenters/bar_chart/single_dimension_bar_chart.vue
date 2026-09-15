<script>
import { GlBarChart } from '@gitlab/ui/src/charts';
import { stackedPresentationOptions } from '@gitlab/ui/src/utils/constants';
import { GL_DARK } from '~/constants';
import {
  getSystemColorScheme,
  listenSystemColorSchemeChange,
  removeListenerSystemColorSchemeChange,
} from '~/lib/utils/css_utils';
import { DISPLAY_TYPES } from '../../../constants';
import {
  baseFieldKeyOf,
  buildBarSeriesData,
  dimensionLabelFormatter,
  labelWithParameter,
  tooltipContentFromParams,
  tooltipTitleFromParams,
} from '../../../utils/chart_data';
import {
  buildFormatterByLabel,
  buildSharedAxisFormatter,
  formatValueForLabel,
  unitFor,
  valueFormatterFor,
  yAxisTitleFor,
} from '../../../utils/value_format';
import FormattedTooltipContent from '../chart/formatted_tooltip_content.vue';
import {
  CATEGORY_SHADES_DARK,
  CATEGORY_SHADES_LIGHT,
  COLOR_BY_CATEGORY,
  COLOR_BY_OPTIONS,
  COLOR_BY_SERIES,
  barCategoryAxisOptions,
  barChartHeightFor,
  colorSeriesByCategory,
  shareLabelFormatter,
} from './bar_chart_options';

export default {
  name: 'SingleDimensionBarChart',
  components: { GlBarChart, FormattedTooltipContent },
  props: {
    data: {
      required: true,
      type: Object,
    },
    dimension: {
      required: true,
      type: Object,
    },
    metrics: {
      required: true,
      type: Array,
    },
    stacked: {
      required: false,
      type: Boolean,
      default: false,
    },
    shareLabels: {
      required: false,
      type: Boolean,
      default: false,
    },
    showAxisTitles: {
      required: false,
      type: Boolean,
      default: true,
    },
    colorBy: {
      required: false,
      type: String,
      default: COLOR_BY_SERIES,
      validator: (value) => COLOR_BY_OPTIONS.includes(value),
    },
  },
  data() {
    return {
      colorScheme: getSystemColorScheme(),
    };
  },
  computed: {
    // Share labels and per-category colours describe one series. With several
    // metrics there is no single total and no single bar per category, so
    // both fall back to the plain rendering.
    singleMetric() {
      return this.metrics.length === 1 ? this.metrics[0] : null;
    },
    // A share of the total only means something for additive metrics, so
    // rates and durations keep plain labels.
    hasShareLabels() {
      return (
        this.shareLabels &&
        Boolean(this.singleMetric) &&
        unitFor(baseFieldKeyOf(this.singleMetric)) === 'count'
      );
    },
    seriesData() {
      return buildBarSeriesData(this.data.nodes, this.dimension, this.metrics);
    },
    categoryShades() {
      return this.colorScheme === GL_DARK ? CATEGORY_SHADES_DARK : CATEGORY_SHADES_LIGHT;
    },
    chartData() {
      if (!this.singleMetric || this.colorBy !== COLOR_BY_CATEGORY) return this.seriesData;
      return colorSeriesByCategory(this.seriesData, this.categoryShades);
    },
    presentation() {
      return this.stacked ? stackedPresentationOptions.stacked : stackedPresentationOptions.tiled;
    },
    formatterByLabel() {
      return buildFormatterByLabel(this.metrics);
    },
    sharedAxisFormatter() {
      return buildSharedAxisFormatter(this.metrics);
    },
    dimensionLabel() {
      return labelWithParameter(this.dimension);
    },
    categoryFormatter() {
      return dimensionLabelFormatter(this.data.nodes, this.dimension);
    },
    // Share labels are for the axis only. The tooltip keeps the plain label,
    // since its body already lists the value.
    axisLabelFormatter() {
      if (!this.hasShareLabels) return this.categoryFormatter;

      const [points] = Object.values(this.seriesData);
      return shareLabelFormatter(points ?? [], {
        formatLabel: this.categoryFormatter,
        formatValue: valueFormatterFor(this.singleMetric),
      });
    },
    // GlBarChart flips the axes: the metric/value axis is x, and the
    // dimension/category axis is y. yAxisTitleFor derives a title from the
    // metrics regardless of which axis it ends up on.
    xAxisTitle() {
      return this.showAxisTitles ? yAxisTitleFor(this.metrics) : '';
    },
    yAxisTitle() {
      return this.showAxisTitles ? this.dimensionLabel : '';
    },
    // Every series maps the same nodes in order, so the first series' tuples
    // carry all the category values; sizing needs their display labels.
    categoryLabels() {
      const [firstSeries] = Object.values(this.seriesData);
      return (firstSeries ?? []).map(([, category]) => this.axisLabelFormatter(category));
    },
    chartHeight() {
      return barChartHeightFor(this.categoryLabels.length, {
        axisTitle: this.showAxisTitles,
        barsPerRow: this.stacked ? 1 : this.metrics.length,
      });
    },
    chartOptions() {
      return {
        ...barCategoryAxisOptions(this.categoryLabels, {
          formatter: this.axisLabelFormatter,
          axisTitle: this.showAxisTitles,
          shareLabels: this.hasShareLabels,
        }),
        ...(this.sharedAxisFormatter
          ? { xAxis: { axisLabel: { formatter: this.sharedAxisFormatter } } }
          : {}),
      };
    },
  },
  created() {
    listenSystemColorSchemeChange(this.setColorScheme);
  },
  beforeDestroy() {
    removeListenerSystemColorSchemeChange(this.setColorScheme);
  },
  methods: {
    setColorScheme(scheme) {
      this.colorScheme = scheme;
    },
    formatValueByLabel(label, value) {
      return formatValueForLabel(this.formatterByLabel, label, value);
    },
    contentFromParams(params) {
      return tooltipContentFromParams(params, DISPLAY_TYPES.BAR_CHART);
    },
    tooltipTitle(params) {
      return tooltipTitleFromParams(params, {
        formatLabel: this.categoryFormatter,
        axisName: this.dimensionLabel,
        displayType: DISPLAY_TYPES.BAR_CHART,
      });
    },
  },
};
</script>

<template>
  <gl-bar-chart
    :data="chartData"
    :option="chartOptions"
    :presentation="presentation"
    :height="chartHeight"
    :x-axis-title="xAxisTitle"
    :y-axis-title="yAxisTitle"
  >
    <template #tooltip-title="{ params }">{{ tooltipTitle(params) }}</template>
    <template #tooltip-content="{ params }">
      <formatted-tooltip-content
        :content="contentFromParams(params)"
        :format-value="formatValueByLabel"
      />
    </template>
  </gl-bar-chart>
</template>
