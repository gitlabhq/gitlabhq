<script>
import { GlPopover } from '@gitlab/ui';
import { GlChart } from '@gitlab/ui/src/charts';
import { colorFromBackground } from '@gitlab/ui/src/utils/utils';
import { labelColorOptions } from '@gitlab/ui/src/utils/constants';
import { heatmapHues } from '@gitlab/ui/src/utils/charts/theme';
import { defaultHeight as DEFAULT_CHART_HEIGHT_PX } from '@gitlab/ui/src/utils/charts/config';
import {
  GL_COLOR_DATA_BLUE_100,
  GL_COLOR_DATA_BLUE_50,
  GL_COLOR_NEUTRAL_0,
  GL_COLOR_NEUTRAL_50,
  GL_COLOR_NEUTRAL_800,
  GL_COLOR_NEUTRAL_950,
} from '@gitlab/ui/src/tokens/build/js/tokens';
import { clamp, merge, uniqueId } from 'lodash-es';
import {
  getSystemColorScheme,
  listenSystemColorSchemeChange,
  removeListenerSystemColorSchemeChange,
} from '~/lib/utils/css_utils';
import { GL_DARK } from '~/constants';

const AVG_CHAR_WIDTH_PX = 7; // ~glyph width of the 12px axis-label font
const MIN_ROW_LABEL_WIDTH_PX = 8 * AVG_CHAR_WIDTH_PX;
const MAX_ROW_LABEL_WIDTH_PX = 160; // past this, ECharts ellipsizes by pixel width
const ROW_LABEL_GUTTER_PX = 16;
const MIN_ROW_HEIGHT_PX = 32;
const MAX_ROW_HEIGHT_PX = 120;
const COLUMN_LABEL_HEIGHT_PX = 32;
const GRID_PADDING_PX = 8;
const CELL_BORDER_PX = 2;
const MAX_HORIZONTAL_LABEL_PX = 900; // rough usable width of a full-width panel
const MIN_COLUMN_LABEL_WIDTH_PX = 48;
const MAX_COLUMN_LABEL_WIDTH_PX = 160;

// Restricts the hover handlers to this chart's own series, so anything a
// caller merges in through `options` cannot drive the tooltip.
const CELL_QUERY = { seriesIndex: 0 };

// heatmapHues starts at data blue 200, too dark to separate small counts, so
// its blues are extended with the two lighter steps of the same scale. The
// ramp reverses in dark mode and its neutral darkens, as the contribution
// calendar's does, so a busier cell is always the more prominent one.
const LIGHT_HUES = [GL_COLOR_DATA_BLUE_50, GL_COLOR_DATA_BLUE_100, ...heatmapHues.slice(1)];

const RAMPS = {
  light: { empty: GL_COLOR_NEUTRAL_50, gap: GL_COLOR_NEUTRAL_0, values: LIGHT_HUES },
  dark: {
    empty: GL_COLOR_NEUTRAL_800,
    gap: GL_COLOR_NEUTRAL_950,
    values: [...LIGHT_HUES].reverse(),
  },
};

const WCAG_AA_CONTRAST = 4.5;

// Preserves first-appearance order, so the caller controls how the axes read.
const orderedUnique = (values) => [...new Set(values)];

// Resolves a value against a piecewise visual map piece the way ECharts does,
// so a cell's label is contrast-checked against the color actually painted.
const pieceMatches = (piece, value) => {
  if (piece.value !== undefined) return value === piece.value;

  const atOrAboveFloor = piece.gt !== undefined ? value > piece.gt : value >= piece.gte;

  return atOrAboveFloor && (piece.lt === undefined || value < piece.lt);
};

export const labelColorOn = (backgroundHex) =>
  colorFromBackground(backgroundHex, WCAG_AA_CONTRAST) === labelColorOptions.dark
    ? GL_COLOR_NEUTRAL_950
    : GL_COLOR_NEUTRAL_0;

export default {
  name: 'HeatMapChart',
  components: { GlChart, GlPopover },
  props: {
    /**
     * Cells to render:
     * `[{ column: String, row: String, value: Number }]`
     * Columns and rows are laid out in first-appearance order. A pair absent
     * from the list renders as a zero-value cell.
     */
    data: {
      type: Array,
      required: false,
      default: () => [],
    },
    /**
     * ECharts option overrides, deep-merged last. Two keys are read here
     * instead: `formatValue` formats the in-cell label and the tooltip, and
     * `bands` replaces the derived shading thresholds with explicit ascending
     * cut-offs.
     */
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      chart: null,
      // Retained after the pointer leaves, so the popover does not animate
      // from the corner as it fades.
      lastCell: null,
      isTooltipVisible: false,
      anchorId: uniqueId('heat-map-cell-'),
      colorScheme: getSystemColorScheme(),
    };
  },
  computed: {
    ramp() {
      return this.colorScheme === GL_DARK ? RAMPS.dark : RAMPS.light;
    },
    columns() {
      return orderedUnique(this.data.map(({ column }) => column));
    },
    rows() {
      return orderedUnique(this.data.map(({ row }) => row));
    },
    cellsByRow() {
      // Nested rather than joined into a string key, so a label containing the
      // separator cannot collide.
      const byRow = new Map();
      this.data.forEach(({ column, row, value }) => {
        if (!byRow.has(row)) byRow.set(row, new Map());
        byRow.get(row).set(column, value);
      });

      return byRow;
    },
    values() {
      return this.rows.flatMap((row) =>
        this.columns.map((column) => this.cellsByRow.get(row)?.get(column) ?? 0),
      );
    },
    // Counts are heavily skewed, so equal-width bands would leave nearly every
    // cell in the lowest one.
    // No more bands than there are distinct values to put in them, so a grid
    // holding only ones and twos does not paint them at opposite ends of the
    // ramp.
    bandCount() {
      if (this.options.bands) {
        return Math.min(this.options.bands.length + 1, this.ramp.values.length);
      }

      const distinct = new Set(this.values.filter((value) => value > 0)).size;

      return Math.min(distinct, this.ramp.values.length);
    },
    bandThresholds() {
      if (this.options.bands) return this.options.bands.slice(0, this.ramp.values.length - 1);

      const present = this.values.filter((value) => value > 0);
      if (this.bandCount < 2) return [];

      const min = Math.min(...present);
      const max = Math.max(...present);

      // Anchored to the smallest real value rather than to 1, or a data set
      // that bottoms out well above 1 leaves the lower bands unused.
      return Array.from(
        { length: this.bandCount - 1 },
        (_, index) => min * (max / min) ** ((index + 1) / this.bandCount),
      );
    },
    // Evenly spaced across the whole ramp rather than taken from one end, so
    // however few bands there are they stay far apart.
    bandHues() {
      const { values } = this.ramp;
      const count = Math.max(this.bandCount, 1);
      if (count === 1) return [values[values.length - 1]];

      return Array.from(
        { length: count },
        (_, index) => values[Math.round((index * (values.length - 1)) / (count - 1))],
      );
    },
    // Explicit bands, so each cell's color is known here and its label can be
    // contrast-checked against it.
    valueBands() {
      const thresholds = this.bandThresholds;
      const hues = this.bandHues;

      return hues.map((color, index) => ({
        color,
        from: index === 0 ? 0 : thresholds[index - 1],
        to: index === hues.length - 1 ? Infinity : thresholds[index],
      }));
    },
    dataSeries() {
      return this.rows.flatMap((row, y) =>
        this.columns.map((column, x) => {
          const value = this.cellsByRow.get(row)?.get(column) ?? 0;

          return {
            value: [x, y, value],
            label: { color: labelColorOn(this.colorFor(value)) },
          };
        }),
      );
    },
    visualMapPieces() {
      return [
        { value: 0, color: this.ramp.empty },
        ...this.valueBands.map(({ from, to, color }, index) => ({
          ...(index === 0 ? { gt: 0 } : { gte: from }),
          ...(Number.isFinite(to) && { lt: to }),
          color,
        })),
      ];
    },
    // Aims for the stock chart height, so a couple of rows stretch to fill a
    // panel instead of leaving most of it blank, while keeping every cell
    // within a readable band. An explicit height at all is what stops the
    // chart collapsing, since nothing above it in a panel has one.
    chartHeight() {
      const chrome = COLUMN_LABEL_HEIGHT_PX + GRID_PADDING_PX * 2;
      const rows = Math.max(this.rows.length, 1);

      return clamp(
        DEFAULT_CHART_HEIGHT_PX,
        rows * MIN_ROW_HEIGHT_PX + chrome,
        rows * MAX_ROW_HEIGHT_PX + chrome,
      );
    },
    // Every column keeps a label, so they are truncated to a share of the
    // available width rather than angled or dropped. A caller wanting them
    // read in full needs fewer columns.
    columnLabelWidth() {
      return clamp(
        MAX_HORIZONTAL_LABEL_PX / Math.max(this.columns.length, 1),
        MIN_COLUMN_LABEL_WIDTH_PX,
        MAX_COLUMN_LABEL_WIDTH_PX,
      );
    },
    rowLabelWidth() {
      const longest = this.rows.reduce((max, label) => Math.max(max, String(label).length), 0);
      return clamp(longest * AVG_CHAR_WIDTH_PX, MIN_ROW_LABEL_WIDTH_PX, MAX_ROW_LABEL_WIDTH_PX);
    },
    fullOptions() {
      const { formatValue, bands, ...echartsOptions } = this.options;
      const categoryAxis = {
        type: 'category',
        z: 3,
        axisTick: { show: false },
        axisLine: { show: false },
        // A heatmap series has no per-cell margin, so the gaps between cells
        // are split lines drawn in the colour behind the grid.
        splitLine: {
          show: true,
          interval: 0,
          lineStyle: { color: this.ramp.gap, width: CELL_BORDER_PX },
        },
      };

      const base = {
        // A heatmap series throws without a visual map.
        visualMap: { show: false, type: 'piecewise', pieces: this.visualMapPieces },
        series: {
          type: 'heatmap',
          data: this.dataSeries,
          // Above the grid background, which would otherwise paint over the
          // cells, and below the axes so the gaps stay visible.
          z: 2,
          label: { show: true, formatter: ({ value }) => this.formatValue(value[2]) },
        },
        grid: {
          left: this.rowLabelWidth + ROW_LABEL_GUTTER_PX,
          right: GRID_PADDING_PX * 2,
          top: GRID_PADDING_PX,
          bottom: COLUMN_LABEL_HEIGHT_PX,
          show: true,
          borderWidth: 0,
          backgroundColor: this.ramp.empty,
        },
        xAxis: {
          ...categoryAxis,
          data: this.columns,
          // ECharts hides labels that would overlap, which silently drops most
          // of them once there are more than a handful of columns.
          axisLabel: {
            interval: 0,
            hideOverlap: false,
            width: this.columnLabelWidth,
            overflow: 'truncate',
          },
        },
        yAxis: {
          ...categoryAxis,
          data: this.rows,
          // A category axis puts its first entry at the bottom, which would
          // read the rows back to front.
          inverse: true,
          axisLabel: { width: this.rowLabelWidth, overflow: 'truncate' },
        },
      };

      return merge(base, echartsOptions);
    },
    // A display:none target gives the popover nothing to anchor to.
    anchorStyle() {
      const { left = 0, top = 0 } = this.lastCell ?? {};

      return {
        left: `${left}px`,
        top: `${top}px`,
        width: '1px',
        height: '1px',
        pointerEvents: 'none',
      };
    },
    tooltipTitle() {
      if (!this.lastCell) return '';

      return `${this.lastCell.row} · ${this.lastCell.column}`;
    },
  },
  created() {
    listenSystemColorSchemeChange(this.setColorScheme);
  },
  beforeDestroy() {
    removeListenerSystemColorSchemeChange(this.setColorScheme);
    this.chart?.off('mouseover', this.onCellOver);
    this.chart?.off('mouseout', this.onCellOut);
  },
  methods: {
    setColorScheme(scheme) {
      this.colorScheme = scheme;
    },
    formatValue(value) {
      return this.options.formatValue?.(value) ?? String(value);
    },
    colorFor(value) {
      const piece = this.visualMapPieces.find((candidate) => pieceMatches(candidate, value));

      // Nothing matches a negative value, which this chart has no meaning for.
      return (piece ?? this.visualMapPieces[0]).color;
    },
    onCreated(chart) {
      this.chart = chart;
      // An axis pointer would only resolve the column, not the cell.
      chart.on('mouseover', CELL_QUERY, this.onCellOver);
      chart.on('mouseout', CELL_QUERY, this.onCellOut);
    },
    onCellOver({ value }) {
      if (!Array.isArray(value)) return;

      const [x, y, cellValue] = value;
      if (cellValue == null) return;

      const point = this.chart.convertToPixel({ seriesIndex: 0 }, [x, y]);
      if (!point) return;

      const [left, top] = point;

      this.lastCell = {
        column: this.columns[x],
        row: this.rows[y],
        value: cellValue,
        left,
        top,
      };
      this.isTooltipVisible = true;
    },
    onCellOut() {
      this.isTooltipVisible = false;
    },
  },
};
</script>

<template>
  <div
    class="gl-chart-h-auto gl-relative gl-flex gl-grow gl-flex-col"
    :style="{ minHeight: `${chartHeight}px` }"
  >
    <gl-chart
      :options="fullOptions"
      height="auto"
      responsive
      class="gl-grow gl-overflow-hidden"
      data-testid="heat-map-chart"
      @created="onCreated"
    />
    <div :id="anchorId" :style="anchorStyle" class="gl-chart-tooltip"></div>
    <gl-popover
      :target="anchorId"
      :container="anchorId"
      :show="isTooltipVisible"
      placement="top"
      triggers=""
    >
      <!-- Withheld until a cell is hovered, so a scoped slot never receives
           undefined bindings. -->
      <template #title>
        <slot v-if="lastCell" name="tooltip-title" v-bind="lastCell">{{ tooltipTitle }}</slot>
      </template>
      <slot v-if="lastCell" name="tooltip-content" v-bind="lastCell">
        {{ formatValue(lastCell.value) }}
      </slot>
    </gl-popover>
  </div>
</template>
