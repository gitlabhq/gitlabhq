<script>
import { GlChart } from '@gitlab/ui/src/charts';
import { HEIGHT_AUTO_CLASSES } from '@gitlab/ui/src/utils/charts/constants';
import { GL_COLOR_ORANGE_400 } from '@gitlab/ui/src/tokens/build/js/tokens';
import { merge } from 'lodash-es';
import { formatNumber } from '~/locale';
import { formatCountCompact } from '~/glql/utils/value_format';

const BAR_HEIGHT = 7;
const GRID_VERTICAL_PADDING = 8;
const CATEGORY_LABEL_SIZE = 13;

// Matches the fixed label column in the design
const LABEL_COLUMN_WIDTH = 164;
const LABEL_GAP = 12;
const VALUE_LABEL_SIZE = 11;

const VALUE_COLUMN_WIDTH = 96;

export default {
  name: 'BarListChart',
  components: {
    GlChart,
  },
  props: {
    /**
     * Rows to render, in display order:
     * `[{ name: String, value: Number, share: Number }]`
     * `share` is a percentage of the whole and sets the bar length.
     */
    data: {
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
  computed: {
    // ECharts draws a category axis bottom-up, so reverse once to keep the
    // caller's order reading top-down.
    rows() {
      return [...this.data].reverse();
    },
    categories() {
      return this.rows.map(({ name }) => name);
    },
    // Bars are drawn against the full total rather than the largest row, so the
    // track reads as 100% and the gap after a bar is the rest of the total.
    shares() {
      return this.rows.map(({ share }) => share);
    },
    labels() {
      return this.rows.map((row) => this.rowLabel(row));
    },
    fullOptions() {
      const base = {
        grid: {
          top: GRID_VERTICAL_PADDING,
          bottom: GRID_VERTICAL_PADDING,
          left: LABEL_COLUMN_WIDTH,
          right: VALUE_COLUMN_WIDTH,
        },
        // The design shows no value axis and no gridlines.
        xAxis: {
          type: 'value',
          show: false,
          min: 0,
          max: 100,
        },
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
            data: this.shares,
            barWidth: BAR_HEIGHT,
            showBackground: true,
            backgroundStyle: { color: 'var(--gl-background-color-subtle)' },
            itemStyle: { color: GL_COLOR_ORANGE_400 },
            label: {
              show: true,
              position: 'right',
              // ECharts defaults this to a hardcoded #333, which never adapts.
              color: 'var(--gl-chart-axis-text-color)',
              fontSize: VALUE_LABEL_SIZE,
              formatter: ({ dataIndex }) => this.labels[dataIndex] ?? '',
            },
          },
        ],
      };

      return merge({}, base, this.options);
    },
  },
  methods: {
    rowLabel({ value, share }) {
      const formattedShare = formatNumber(share, { maximumFractionDigits: 1 });

      return `${formattedShare}% · ${formatCountCompact(value, { lowercaseThousands: true })}`;
    },
  },
  HEIGHT_AUTO_CLASSES,
};
</script>
<template>
  <div class="gl-relative" :class="$options.HEIGHT_AUTO_CLASSES">
    <gl-chart
      :options="fullOptions"
      height="auto"
      responsive
      class="gl-grow gl-overflow-hidden"
      data-testid="bar-list-chart"
    />
  </div>
</template>
