<script>
import { GlResizeObserverDirective } from '@gitlab/ui';
import { GlChart } from '@gitlab/ui/src/charts';
import { HEIGHT_AUTO_CLASSES } from '@gitlab/ui/src/utils/charts/constants';
import { colorFromDefaultPalette } from '@gitlab/ui/src/utils/charts/theme';
import { merge } from 'lodash-es';
import { formatCountCompact } from '~/glql/utils/value_format';

const SERIES_COUNT = 2;

// Compact because the gutter is a fixed width; lowercase `k` matches the bar list.
const formatValue = (value) => formatCountCompact(value, { lowercaseThousands: true });

const BAR_HEIGHT = 7;
const GRID_VERTICAL_PADDING = 8;
const CATEGORY_LABEL_SIZE = 13;
const VALUE_LABEL_SIZE = 11;

const VALUE_COLUMN_WIDTH = 64;
const LEGEND_HEIGHT = 32;
const LEGEND_ICON_SIZE = 8;

// A bar's track spans the whole grid, so the axes must outrank the series
// (default z 2) or the track paints over the category labels.
const LABEL_Z = 3;

// Bars grow outward from zero, so each axis runs past zero to inset it from
// the midpoint and keep the category column clear.
const CENTER_GAP = 0.2;

const CENTER_LABEL_PADDING = 8;

// Shared fragments. Anything the gitlab-ui chart theme already sets is omitted.
const DEFAULT_DIVERGING_BAR_CHART_OPTIONS = {
  grid: { top: GRID_VERTICAL_PADDING, bottom: LEGEND_HEIGHT },
  xAxis: { type: 'value', show: false },
  yAxis: { type: 'category', axisTick: { show: false }, z: LABEL_Z },
  series: {
    type: 'bar',
    barWidth: BAR_HEIGHT,
    showBackground: true,
    backgroundStyle: { color: 'var(--gl-background-color-subtle)' },
  },
  legend: {
    bottom: 0,
    icon: 'square',
    itemWidth: LEGEND_ICON_SIZE,
    itemHeight: LEGEND_ICON_SIZE,
    textStyle: { fontSize: VALUE_LABEL_SIZE },
  },
};

export default {
  name: 'DivergingBarChart',
  components: {
    GlChart,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  props: {
    /**
     * `[{ name: String, values: [Number, Number] }]`, in display order.
     * `values[0]` grows left from the centre, `values[1]` grows right.
     */
    data: {
      type: Array,
      required: false,
      default: () => [],
    },
    /** In the same order as each row's `values`. */
    seriesNames: {
      type: Array,
      required: true,
      validator: (names) => names.length === SERIES_COUNT,
    },
    /** Indexed as `values`; falls back to a plain count. */
    valueFormatters: {
      type: Array,
      required: false,
      default: () => [],
    },
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      containerWidth: 0,
    };
  },
  computed: {
    // The centre is a share of the width but label text is not, so truncating
    // needs the band in pixels.
    categoryLabelWidth() {
      const band = (this.containerWidth - VALUE_COLUMN_WIDTH * 2) * (CENTER_GAP / (1 + CENTER_GAP));
      return band > CENTER_LABEL_PADDING ? band - CENTER_LABEL_PADDING : null;
    },
    // ECharts draws a category axis bottom-up.
    rows() {
      return [...this.data].reverse();
    },
    categories() {
      return this.rows.map(({ name }) => name);
    },
    valuesBySeries() {
      return Array.from({ length: SERIES_COUNT }, (_, series) =>
        this.rows.map(({ values }) => values?.[series] ?? 0),
      );
    },
    labelsBySeries() {
      return this.valuesBySeries.map((values, series) => {
        const format = this.valueFormatters[series] ?? formatValue;
        return values.map((value) => format(value));
      });
    },
    fullOptions() {
      const { grid, xAxis, series, legend } = DEFAULT_DIVERGING_BAR_CHART_OPTIONS;

      const base = {
        grid: [
          { ...grid, left: VALUE_COLUMN_WIDTH, right: '50%' },
          { ...grid, left: '50%', right: VALUE_COLUMN_WIDTH },
        ],
        xAxis: this.valuesBySeries.map((values, index) => {
          const max = Math.max(...values, 0) || 1;

          return { ...xAxis, gridIndex: index, min: -max * CENTER_GAP, max, inverse: index === 0 };
        }),
        yAxis: [
          this.categoryAxis(),
          // Axes, not bar labels, so values sit in a fixed gutter. Each series
          // binds to its own, so the right half needs no separate axis.
          this.valueAxis({ gridIndex: 0, position: 'left', series: 0 }),
          this.valueAxis({ gridIndex: 1, position: 'right', series: 1 }),
        ],
        series: this.valuesBySeries.map((values, index) => ({
          ...series,
          name: this.seriesNames[index],
          xAxisIndex: index,
          yAxisIndex: index + 1,
          data: values,
          itemStyle: { color: colorFromDefaultPalette(index) },
        })),
        legend,
      };

      return merge({}, base, this.options);
    },
  },
  methods: {
    onResize({ contentRect }) {
      this.containerWidth = contentRect.width;
    },
    // The left grid's inner edge is the midpoint, so labels straddle both halves.
    categoryAxis() {
      return {
        ...DEFAULT_DIVERGING_BAR_CHART_OPTIONS.yAxis,
        gridIndex: 0,
        data: this.categories,
        position: 'right',
        axisLabel: {
          align: 'center',
          margin: 0,
          fontSize: CATEGORY_LABEL_SIZE,
          color: 'var(--gl-text-color-default)',
          width: this.categoryLabelWidth,
          overflow: this.categoryLabelWidth ? 'truncate' : 'none',
        },
      };
    },
    valueAxis({ gridIndex, position, series }) {
      return {
        ...DEFAULT_DIVERGING_BAR_CHART_OPTIONS.yAxis,
        gridIndex,
        data: this.categories,
        position,
        axisLabel: {
          fontSize: VALUE_LABEL_SIZE,
          formatter: (_, index) => this.labelsBySeries[series][index],
        },
      };
    },
  },
  HEIGHT_AUTO_CLASSES,
};
</script>
<template>
  <div v-gl-resize-observer="onResize" class="gl-relative" :class="$options.HEIGHT_AUTO_CLASSES">
    <gl-chart
      :options="fullOptions"
      height="auto"
      responsive
      class="gl-grow gl-overflow-hidden"
      data-testid="diverging-bar-chart"
    />
  </div>
</template>
