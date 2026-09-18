<script>
import { GlChart } from '@gitlab/ui/src/charts';
import { merge } from 'lodash-es';
import { formatNumber } from '~/locale';
import { formatCountCompact } from '~/glql/utils/value_format';
import {
  BAR_COLOR_DEFAULT,
  BAR_COLOR_OPTIONS,
  BAR_COLOR_TOKENS,
  SCALE_DEFAULT,
  SCALE_LOG,
  SCALE_OPTIONS,
  SCALE_TOTAL,
  VALUE_LABELS_DEFAULT,
  VALUE_LABELS_OPTIONS,
  VALUE_LABELS_VALUE,
} from './bar_list_chart_options';

const BAR_HEIGHT = 7;
const GRID_VERTICAL_PADDING = 8;

const ROW_HEIGHT = 28;
const CATEGORY_LABEL_SIZE = 13;

// Matches the fixed label column in the design
const LABEL_COLUMN_WIDTH = 164;
const LABEL_GAP = 12;
const VALUE_LABEL_SIZE = 11;
const VALUE_ONLY_LABEL_SIZE = 12;

const VALUE_COLUMN_WIDTH = 96;
// A trend pill follows the value, so the column grows to keep both clear of the edge.
const VALUE_WITH_TREND_COLUMN_WIDTH = 160;

// ECharts takes pixel numbers for text sizes, so the pill cannot use the rem-valued
// sizing tokens.
const TREND_LABEL_SIZE = 11;
const TREND_LINE_HEIGHT = 16;
const TREND_PILL_PADDING = [1, 6];
const TREND_PILL_RADIUS = 8;
// Space between the value and its trend pill, so the pill reads as a separate mark.
const TREND_GAP = 8;

// ECharts rich text style names, one per GlBadge variant the pill can take.
const TREND_STYLE_BY_VARIANT = {
  success: 'trendSuccess',
  danger: 'trendDanger',
  neutral: 'trendNeutral',
};

// The badge tokens, so the pill matches the badge a stat renders. GlChart's SVG renderer
// resolves the CSS variables.
const TREND_COLOR_BY_VARIANT = {
  success: 'var(--gl-badge-success-text-color-default)',
  danger: 'var(--gl-badge-danger-text-color-default)',
  neutral: 'var(--gl-badge-neutral-text-color-default)',
};

const TREND_BACKGROUND_COLOR_BY_VARIANT = {
  success: 'var(--gl-badge-success-background-color-default)',
  danger: 'var(--gl-badge-danger-background-color-default)',
  neutral: 'var(--gl-badge-neutral-background-color-default)',
};

const trendStyleFor = (variant) => ({
  fontSize: TREND_LABEL_SIZE,
  lineHeight: TREND_LINE_HEIGHT,
  padding: TREND_PILL_PADDING,
  borderRadius: TREND_PILL_RADIUS,
  color: TREND_COLOR_BY_VARIANT[variant],
  backgroundColor: TREND_BACKGROUND_COLOR_BY_VARIANT[variant],
});

const trendStyleName = (variant) =>
  TREND_STYLE_BY_VARIANT[variant] ?? TREND_STYLE_BY_VARIANT.neutral;

const LOG_BASE = 10;
// A log axis has no zero, and ECharts grows its bars from 1, not from the axis start.
const LOG_AXIS_MIN = 1;
// Offset the values when using log scaling. This is to prevent a value of 1 appearing the same
// as a 0 in the chart. The shift is negligible for large values, so the spread is kept,
// and labels show the real count anyways.
const LOG_VALUE_OFFSET = 1;

const TREND_RICH_STYLES = {
  // An empty token whose horizontal padding is the gap; rich text has no margin.
  trendGap: { padding: [0, TREND_GAP / 2] },
  ...Object.fromEntries(
    Object.entries(TREND_STYLE_BY_VARIANT).map(([variant, name]) => [name, trendStyleFor(variant)]),
  ),
};

export default {
  name: 'BarListChart',
  components: {
    GlChart,
  },
  props: {
    /**
     * Rows to render, in display order:
     * `[{ name: String, value: Number, share: Number, label?: String, trend?: { text: String, variant: String } }]`
     * `share` is a percentage of the whole and sets the bar length. `label` stands in for the
     * formatted value when the value is not a count, such as a duration. `trend` renders as a
     * pill after the value label, coloured by its GlBadge `variant` (`success`, `danger`, `neutral`).
     */
    data: {
      type: Array,
      required: false,
      default: () => [],
    },
    /**
     * `shareAndValue` labels each bar `89% · 85.6k`; `value` labels it with the value alone,
     * in full digits, for a list where the count matters more than the share.
     */
    valueLabels: {
      type: String,
      required: false,
      default: VALUE_LABELS_DEFAULT,
      validator: (value) => VALUE_LABELS_OPTIONS.includes(value),
    },
    /**
     * What a bar's length is measured against. `total` (default) plots each row's `share`, so
     * the track reads as 100% of the whole; `max` sizes bars against the largest `value`, so
     * that row fills the track and the rest compare to it. `log` plots the values on a
     * base-10 log axis rather than a percentage of the track, so dominant rows do not flatten
     * the rest. Labels keep showing the true value and `share` no matter the scale.
     */
    scale: {
      type: String,
      required: false,
      default: SCALE_DEFAULT,
      validator: (value) => SCALE_OPTIONS.includes(value),
    },
    color: {
      type: String,
      required: false,
      default: BAR_COLOR_DEFAULT,
      validator: (value) => BAR_COLOR_OPTIONS.includes(value),
    },
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    // ECharts draws a category axis bottom-up, so reverse once to keep the
    // caller's order reading top-down.
    rows() {
      return [...this.data].reverse();
    },
    categories() {
      return this.rows.map(({ name }) => name);
    },
    // By default bars are drawn against the full total rather than the largest row, so
    // the track reads as 100% and the gap after a bar is the rest of the total.
    lengths() {
      if (this.scale === SCALE_TOTAL) return this.rows.map(({ share }) => share);

      const max = Math.max(0, ...this.rows.map(({ value }) => value));
      return this.rows.map(({ value }) => (max ? (value / max) * 100 : 0));
    },
    labels() {
      return this.rows.map((row) => this.rowLabel(row));
    },
    hasTrends() {
      return this.rows.some(({ trend }) => trend);
    },
    valueOnly() {
      return this.valueLabels === VALUE_LABELS_VALUE;
    },
    chartHeight() {
      return this.rows.length * ROW_HEIGHT + GRID_VERTICAL_PADDING * 2;
    },
    fullOptions() {
      const base = {
        grid: {
          top: GRID_VERTICAL_PADDING,
          bottom: GRID_VERTICAL_PADDING,
          left: LABEL_COLUMN_WIDTH,
          right: this.hasTrends ? VALUE_WITH_TREND_COLUMN_WIDTH : VALUE_COLUMN_WIDTH,
        },
        xAxis: this.valueAxis,
        yAxis: {
          type: 'category',
          data: this.categories,
          axisTick: { show: false },
          axisLabel: {
            align: 'right',
            fontSize: CATEGORY_LABEL_SIZE,
            width: LABEL_COLUMN_WIDTH - LABEL_GAP * 2,
            overflow: 'truncate',
          },
        },
        series: [
          {
            type: 'bar',
            // Only the log scale plots values directly; the rest plot a percentage of the track.
            data: this.isLogScale ? this.logScaleValues : this.lengths,
            barWidth: BAR_HEIGHT,
            showBackground: true,
            backgroundStyle: { color: 'var(--gl-background-color-subtle)' },
            itemStyle: {
              color: BAR_COLOR_TOKENS[this.color],
            },
            label: {
              show: true,
              position: 'right',
              // ECharts defaults this to a hardcoded #333, which never adapts.
              color: this.valueOnly
                ? 'var(--gl-text-color-default)'
                : 'var(--gl-chart-axis-text-color)',
              fontSize: this.valueOnly ? VALUE_ONLY_LABEL_SIZE : VALUE_LABEL_SIZE,
              fontWeight: this.valueOnly ? 'bold' : 'normal',
              rich: TREND_RICH_STYLES,
              formatter: ({ dataIndex }) => this.labels[dataIndex] ?? '',
            },
          },
        ],
      };

      return merge({}, base, this.options);
    },
    isLogScale() {
      return this.scale === SCALE_LOG;
    },
    logScaleValues() {
      return this.isLogScale
        ? this.rows.map(({ value }) => Math.max(value, 0) + LOG_VALUE_OFFSET)
        : [];
    },
    maxLogScaleValue() {
      // Every value clears the minimum already, so it only covers an empty chart here.
      const max = Math.max(LOG_AXIS_MIN, ...this.logScaleValues);

      return LOG_BASE ** (Math.floor(Math.log10(max)) + 1);
    },
    valueAxis() {
      if (this.isLogScale) {
        return {
          type: 'log',
          logBase: LOG_BASE,
          show: false,
          min: LOG_AXIS_MIN,
          max: this.maxLogScaleValue,
        };
      }

      return { type: 'value', show: false, min: 0, max: 100 };
    },
  },
  methods: {
    rowLabel({ value, share, label: valueLabel, trend }) {
      const formattedValue =
        valueLabel ??
        (this.valueOnly
          ? formatNumber(value)
          : formatCountCompact(value, { lowercaseThousands: true }));
      const label = this.valueOnly
        ? formattedValue
        : `${formatNumber(share, { maximumFractionDigits: 1 })}% · ${formattedValue}`;

      // ECharts rich text: `{styleName|text}` picks a style from `label.rich`.
      return trend ? `${label}{trendGap|}{${trendStyleName(trend.variant)}|${trend.text}}` : label;
    },
  },
};
</script>
<template>
  <div
    class="gl-chart-h-auto gl-relative gl-flex gl-flex-col"
    :style="{ height: `${chartHeight}px` }"
  >
    <gl-chart
      :options="fullOptions"
      height="auto"
      responsive
      class="gl-grow gl-overflow-hidden"
      data-testid="bar-list-chart"
    />
  </div>
</template>
