<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import BarListChart from '~/analytics/analytics_dashboards/components/visualizations/bar_list_chart.vue';
import {
  BAR_COLOR_DEFAULT,
  BAR_COLOR_OPTIONS,
  SCALE_DEFAULT,
  SCALE_OPTIONS,
  VALUE_LABELS_DEFAULT,
  VALUE_LABELS_OPTIONS,
} from '~/analytics/analytics_dashboards/components/visualizations/bar_list_chart_options';
import {
  dimensionValue,
  dimensionLabelFormatter,
  dimensionsOf,
  labelWithParameter,
  metricsOf,
} from '../../utils/chart_data';
import { valueFormatterFor } from '../../utils/value_format';
import DimensionRoutedChart from './chart/dimension_routed_chart.vue';
import { NO_VALUE, trendPresentationFor } from './utils/stat';
import {
  TREND_PREVIOUS_KEY,
  hasTemporalDimension,
  hasUniqueRowKeys,
  withTrendValues,
} from './utils/table';
import { formatSignedChange, trendChangeFor } from './utils/trend';

// Six rows plus a rolled-up Other row, which is the shape of the design this
// display type was built for. A query returning fewer rows is unaffected.
const DEFAULT_MAX_ROWS = 6;

const sumOf = (rows, key) => rows.reduce((sum, row) => sum + row[key], 0);

// The display options a block may set, each with the values it accepts.
const DISPLAY_OPTIONS = {
  valueLabels: VALUE_LABELS_OPTIONS,
  color: BAR_COLOR_OPTIONS,
  scale: SCALE_OPTIONS,
};

export default {
  name: 'BarListPresenter',
  components: {
    BarListChart,
    DimensionRoutedChart,
    GlSkeletonLoader,
  },
  props: {
    data: {
      required: false,
      type: Object,
      default: () => ({ nodes: [] }),
    },
    /**
     * Result of the same query over the previous period. When present, each row gets a trend.
     */
    comparisonData: {
      required: false,
      type: Object,
      default: null,
    },
    fields: {
      required: false,
      type: Array,
      default: () => [],
    },
    loading: {
      required: false,
      type: Boolean,
      default: false,
    },
    displayConfig: {
      required: false,
      type: Object,
      default: () => ({}),
    },
    source: {
      required: false,
      type: String,
      default: '',
    },
  },
  emits: { error: null },
  computed: {
    queryMetrics() {
      return metricsOf(this.fields);
    },
    // Without a dimension the query returns a single node, and each metric becomes a row.
    metricRows() {
      return dimensionsOf(this.fields).length === 0 && this.queryMetrics.length > 0;
    },
    maxRows() {
      const maxRows = Number(this.displayConfig.maxRows);
      return Number.isInteger(maxRows) && maxRows > 0 ? maxRows : DEFAULT_MAX_ROWS;
    },
    valueLabels() {
      return this.displayConfig?.valueLabels ?? VALUE_LABELS_DEFAULT;
    },
    color() {
      return this.displayConfig?.color ?? BAR_COLOR_DEFAULT;
    },
    scale() {
      return this.displayConfig?.scale ?? SCALE_DEFAULT;
    },
    // An unknown value is a block error, as for the stat presenter's variant, rather than a
    // silent fallback to the default.
    displayConfigError() {
      const unknown = Object.entries(DISPLAY_OPTIONS).find(
        ([key, options]) =>
          this.displayConfig?.[key] != null && !options.includes(this.displayConfig[key]),
      );
      if (!unknown) return null;

      const [key, options] = unknown;

      return sprintf(
        __('Unknown `%{key}`: `%{value}`. Supported values are: %{supportedValues}.'),
        {
          key,
          value: this.displayConfig[key],
          supportedValues: options.map((option) => `\`${option}\``).join(', '),
        },
      );
    },
  },
  watch: {
    displayConfigError: {
      immediate: true,
      handler(message) {
        if (message) this.$emit('error', new Error(message));
      },
    },
  },
  methods: {
    // One row per metric from the single node, in query order, labelled in the metric's unit so
    // two quantiles of a duration read as durations rather than counts. A metric the response
    // left null, such as a quantile over no rows, keeps an empty bar and shows no value.
    metricRowsFor(metrics) {
      const node = this.data?.nodes?.[0] ?? {};
      const rows = metrics.map((metric) => {
        const value = node[metric.key];

        return {
          name: labelWithParameter(metric),
          value: value ?? 0,
          label: value == null ? NO_VALUE : valueFormatterFor(metric)(value),
        };
      });
      const total = sumOf(rows, 'value');

      return rows.map((row) => ({ ...row, share: total ? (row.value / total) * 100 : 0 }));
    },
    // Previous-period values, one per node, paired on dimension identity under the same
    // guards as the table's trend column. Null when nothing can be paired.
    previousValuesFor(nodes, dimension, metric) {
      const comparisonNodes = this.comparisonData?.nodes;
      if (!comparisonNodes?.length) return null;

      const dimensions = [dimension];
      if (hasTemporalDimension(dimensions)) return null;
      // Both periods: a duplicate identity on either side mispairs rows on the other.
      if (!hasUniqueRowKeys(nodes, dimensions)) return null;
      if (!hasUniqueRowKeys(comparisonNodes, dimensions)) return null;

      return withTrendValues(nodes, { comparisonNodes, dimensions, metric }).map(
        (node) => node[TREND_PREVIOUS_KEY],
      );
    },
    trendFor(metric, { value, previousValue }) {
      const trend = trendPresentationFor(this.source, metric, { value, previousValue });
      if (!trend) return null;

      const change = trendChangeFor(value, previousValue);

      return {
        // A move away from 0 has no percentage, so the pill keeps the badge's "New".
        text: change == null ? trend.metaText : formatSignedChange(change),
        variant: trend.variant,
      };
    },
    // Share is each row's % of the grand total rather than of the largest row
    rowsFor(dimension, metric) {
      const nodes = this.data?.nodes ?? [];
      const formatLabel = dimensionLabelFormatter(nodes, dimension);
      const previousValues = this.previousValuesFor(nodes, dimension, metric);

      const rows = nodes.map((node, index) => ({
        name: formatLabel(dimensionValue(node, dimension)),
        value: node[metric.key] ?? 0,
        previousValue: previousValues?.[index] ?? null,
      }));
      const total = sumOf(rows, 'value');
      const shareOf = (value) => (total ? (value / total) * 100 : 0);
      const toRow = ({ name, value, previousValue }) => {
        const trend = previousValues && this.trendFor(metric, { value, previousValue });

        return { name, value, share: shareOf(value), ...(trend && { trend }) };
      };
      const descending = rows.sort((a, b) => b.value - a.value);

      if (descending.length <= this.maxRows + 1) {
        return descending.map(toRow);
      }

      const remainder = descending.slice(this.maxRows);
      // One row with no previous value leaves the roll-up's previous total unknown too.
      const remainderKnown = remainder.every(({ previousValue }) => previousValue != null);

      return [
        ...descending.slice(0, this.maxRows).map(toRow),
        toRow({
          name: sprintf(s__('Glql|Other (%{count})'), { count: remainder.length }),
          value: sumOf(remainder, 'value'),
          previousValue: remainderKnown ? sumOf(remainder, 'previousValue') : null,
        }),
      ];
    },
  },
};
</script>

<template>
  <div v-if="metricRows">
    <gl-skeleton-loader v-if="loading" />
    <bar-list-chart
      v-else-if="!displayConfigError"
      :data="metricRowsFor(queryMetrics)"
      :value-labels="valueLabels"
      :color="color"
      :scale="scale"
    />
  </div>
  <dimension-routed-chart
    v-else
    display-type="barList"
    :fields="fields"
    :loading="loading"
    :max-dimensions="1"
    @error="$emit('error', $event)"
  >
    <template #one-dimension="{ dimension, metrics }">
      <bar-list-chart
        v-if="!displayConfigError"
        :data="rowsFor(dimension, metrics[0])"
        :value-labels="valueLabels"
        :color="color"
        :scale="scale"
      />
    </template>
  </dimension-routed-chart>
</template>
