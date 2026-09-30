<script>
import { GlChart, GlChartLegend } from '@gitlab/ui/src/charts';
import { colorFromDefaultPalette } from '@gitlab/ui/src/utils/charts/theme';
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
    GlChartLegend,
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
  data() {
    return {
      // Held for GlChartLegend, which drives the chart through it.
      chartInstance: null,
      // Series hidden via the legend. Stacked shares and labels rescale to the
      // visible total, so hiding a dominant series keeps the rest readable.
      hiddenSeries: [],
    };
  },
  computed: {
    // ECharts draws a category axis bottom-up, so reverse once to keep the
    // caller's order reading top-down.
    rows() {
      return [...this.data].reverse();
    },
    // Stacked mode: rows carry `segments: [{ name, value, share }]`, one bar
    // series per segment name, with a legend below the chart.
    stacked() {
      return this.data.some((row) => Array.isArray(row.segments) && row.segments.length);
    },
    seriesNames() {
      const names = [];
      this.data.forEach((row) => {
        (row.segments ?? []).forEach(({ name }) => {
          if (!names.includes(name)) names.push(name);
        });
      });
      return names;
    },
    visibleRowValues() {
      return this.rows.map((row) => {
        const segments = row.segments ?? [];
        if (!segments.some((segment) => segment.value != null)) return row.value;
        return segments
          .filter((segment) => !this.hiddenSeries.includes(segment.name))
          .reduce((sum, segment) => sum + (segment.value ?? 0), 0);
      });
    },
    visibleGrandTotal() {
      return this.visibleRowValues.reduce((sum, value) => sum + value, 0);
    },
    stackedSeries() {
      // The row-total label rides the last series ECharts still renders, so it
      // survives any series being hidden via the legend.
      const visible = this.seriesNames.filter((name) => !this.hiddenSeries.includes(name));
      const lastVisible = visible[visible.length - 1];
      const grand = this.visibleGrandTotal;
      return this.seriesNames.map((name, index) => ({
        type: 'bar',
        stack: 'row',
        name,
        itemStyle: { color: colorFromDefaultPalette(index) },
        barWidth: BAR_HEIGHT,
        showBackground: true,
        backgroundStyle: { color: 'var(--gl-background-color-subtle)' },
        data: this.rows.map((row) => {
          const segment = (row.segments ?? []).find((s) => s.name === name);
          if (!segment) return 0;
          if (segment.value == null || !grand) return segment.share ?? 0;
          return this.hiddenSeries.includes(name) ? 0 : (segment.value / grand) * 100;
        }),
        label: {
          show: name === lastVisible,
          position: 'right',
          color: 'var(--gl-chart-axis-text-color)',
          fontSize: VALUE_LABEL_SIZE,
          formatter: ({ dataIndex }) => this.stackedLabels[dataIndex] ?? '',
        },
      }));
    },
    stackedLabels() {
      return this.visibleRowValues.map((value) =>
        formatCountCompact(value, { lowercaseThousands: true }),
      );
    },
    // Compared by value, so paging to rows with the same series leaves the
    // reader's hidden series alone. Stringified rather than joined, because a
    // dimension value may itself contain the separator.
    seriesKey() {
      return JSON.stringify(this.seriesNames);
    },
    seriesInfo() {
      return this.seriesNames.map((name, index) => ({
        name,
        type: 'bar',
        color: colorFromDefaultPalette(index),
      }));
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
        // The legend renders below the chart in the DOM, so the canvas
        // reserves no room for it.
        grid: {
          top: GRID_VERTICAL_PADDING,
          bottom: GRID_VERTICAL_PADDING,
          left: LABEL_COLUMN_WIDTH,
          right: this.hasTrends ? VALUE_WITH_TREND_COLUMN_WIDTH : VALUE_COLUMN_WIDTH,
        },
        legend: this.stacked
          ? {
              // Hidden, not absent: GlChartLegend toggles series through this
              // component, so it still has to carry the selection state.
              show: false,
              // GlChart applies options in merge mode, where ECharts keeps its own
              // selection state, so every series is pinned explicitly — re-selecting
              // any a data change un-hid.
              selected: Object.fromEntries(
                this.seriesNames.map((name) => [name, !this.hiddenSeries.includes(name)]),
              ),
            }
          : undefined,
        // Stacked bars always plot shares of the track; `scale` applies to one dimension only.
        xAxis: this.stacked ? { type: 'value', show: false, min: 0, max: 100 } : this.valueAxis,
        yAxis: {
          type: 'category',
          data: this.categories,
          axisTick: { show: false },
          axisLabel: {
            align: 'left',
            margin: LABEL_COLUMN_WIDTH - LABEL_GAP,
            fontSize: CATEGORY_LABEL_SIZE,
            width: LABEL_COLUMN_WIDTH - LABEL_GAP * 2,
            overflow: 'truncate',
          },
        },
        series: this.stacked
          ? this.stackedSeries
          : [
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
  watch: {
    // GlChartLegend tracks its hidden entries by position while this tracks
    // them by name, so a changed series list has to clear both at once or the
    // legend ends up greying an entry whose bars are still drawn. The same key
    // remounts the legend, resetting its half.
    seriesKey() {
      this.hiddenSeries = [];
    },
  },
  methods: {
    // GlChart calls setOption in merge mode, which merges series by index and
    // leaves the previous tail on the chart when the list gets shorter.
    // Replacing the series component drops them without remounting the chart,
    // so hidden series and the legend's own state survive a fold or unfold.
    onChartUpdated(chart) {
      chart.setOption({ series: this.fullOptions.series }, { replaceMerge: ['series'] });
    },
    onChartCreated(chart) {
      this.chartInstance = chart;
      chart.on('legendselectchanged', ({ selected }) => {
        this.hiddenSeries = Object.keys(selected).filter((name) => !selected[name]);
      });
    },
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
  <div>
    <div
      class="gl-chart-h-auto gl-relative gl-flex gl-flex-col"
      :style="{ height: `${chartHeight}px` }"
      data-testid="chart-container"
    >
      <gl-chart
        :options="fullOptions"
        height="auto"
        responsive
        class="gl-grow gl-overflow-hidden"
        data-testid="bar-list-chart"
        @created="onChartCreated"
        @updated="onChartUpdated"
      />
    </div>
    <gl-chart-legend
      v-if="stacked && chartInstance"
      :key="seriesKey"
      :chart="chartInstance"
      :series-info="seriesInfo"
      class="gl-mt-3"
    />
  </div>
</template>
