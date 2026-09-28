<script>
import { GlKeysetPagination, GlSkeletonLoader } from '@gitlab/ui';
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
  buildStackedByDimension,
  dimensionValue,
  dimensionLabelFormatter,
  dimensionsOf,
  labelWithParameter,
  metricsOf,
} from '../../utils/chart_data';
import { dimensionMetricValidationError } from '../../utils/chart_validation';
import { valueFormatterFor } from '../../utils/value_format';
import DimensionRoutedChart from './chart/dimension_routed_chart.vue';
import { pageOf, pageSizeFor } from './bar_list/fold_tail';
import TwoDimensionsBarList from './bar_list/two_dimensions_bar_list.vue';
import { listDescriptionError, listDescriptionFor } from './utils/description';
import { hiddenMetricsError, visibleFieldsOf } from './utils/hidden_metrics';
import { NO_VALUE, trendPresentationFor } from './utils/stat';
import { TREND_PREVIOUS_KEY, hasTemporalDimension, withTrendValues } from './utils/table';
import { formatSignedChange, trendChangeFor } from './utils/trend';

// A query returning fewer rows shows no paging controls.
const DEFAULT_MAX_ROWS = 6;

// A second dimension becomes stacked segments; a third has nowhere to go.
const MAX_DIMENSIONS = 2;

// How many secondary-dimension values keep their own stacked segment before
// the rest roll up into an Other segment, keeping the legend legible.
const DEFAULT_MAX_SERIES = 6;

const sumOf = (rows, key) => rows.reduce((sum, row) => sum + row[key], 0);

// The display options a block may set, each with the values it accepts.
const DISPLAY_OPTIONS = {
  valueLabels: VALUE_LABELS_OPTIONS,
  color: BAR_COLOR_OPTIONS,
  scale: SCALE_OPTIONS,
};

export default {
  name: 'BarListPresenter',
  MAX_DIMENSIONS,
  components: {
    BarListChart,
    DimensionRoutedChart,
    TwoDimensionsBarList,
    GlKeysetPagination,
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
  data() {
    return {
      // Display-side: the rows are already fetched, so a page turn makes no
      // request. GlKeysetPagination is here only for its Prev and Next controls.
      page: 0,
    };
  },
  computed: {
    queryMetrics() {
      return metricsOf(this.fields);
    },
    // A dimensioned query normally gets one row per value, but a window metric can't drop its
    // date dimension, so `metricRows` forces one row per metric, read from the first node.
    metricRows() {
      return (
        this.queryMetrics.length > 0 &&
        (dimensionsOf(this.fields).length === 0 || this.displayConfig?.metricRows === true)
      );
    },
    description() {
      return listDescriptionFor({
        description: this.displayConfig?.description,
        fields: this.fields,
        data: this.data,
        loading: this.loading,
      });
    },
    visibleFields() {
      return visibleFieldsOf(this.fields, this.displayConfig?.hiddenMetrics);
    },
    barMetrics() {
      return metricsOf(this.visibleFields);
    },
    maxRows() {
      const maxRows = Number(this.displayConfig.maxRows);
      return Number.isInteger(maxRows) && maxRows > 0 ? maxRows : DEFAULT_MAX_ROWS;
    },
    maxSeries() {
      const maxSeries = Number(this.displayConfig.maxSeries);
      return Number.isInteger(maxSeries) && maxSeries > 0 ? maxSeries : DEFAULT_MAX_SERIES;
    },
    // Shares the routed chart's validator and its grouping helper, so the pager
    // can't outlive the chart or drift from the rows it renders.
    totalRows() {
      const dimensions = dimensionsOf(this.visibleFields);
      if (this.metricRows) return 0;

      const routingError = dimensionMetricValidationError({
        displayType: 'barList',
        dimensions,
        metrics: this.barMetrics,
        maxDimensions: MAX_DIMENSIONS,
      });
      if (routingError) return 0;

      const nodes = this.data?.nodes ?? [];
      if (dimensions.length === 1) return nodes.length;

      return buildStackedByDimension({
        nodes,
        primaryDim: dimensions[0],
        secondaryDim: dimensions[1],
        metric: this.barMetrics[0],
      }).groups.length;
    },
    pageSize() {
      return pageSizeFor(this.totalRows, this.maxRows);
    },
    pageCount() {
      return Math.ceil(this.totalRows / this.pageSize);
    },
    hasPreviousPage() {
      return this.page > 0;
    },
    hasNextPage() {
      return this.page + 1 < this.pageCount;
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
      const descriptionError = listDescriptionError(this.displayConfig?.description, this.fields);
      if (descriptionError) return descriptionError;

      const hiddenError = hiddenMetricsError(this.displayConfig?.hiddenMetrics, this.fields);
      if (hiddenError) return hiddenError;

      if (this.metricRows && !this.barMetrics.length) {
        return s__('Glql|barList display type requires at least one metric not in `hiddenMetrics`');
      }

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
    // A new result set invalidates the current page, so paging restarts.
    data() {
      this.page = 0;
    },
    // Anything that shrinks the row count can strand the page past the last
    // one, where the controls are gone and there is no way back.
    pageCount(count) {
      if (this.page >= count) this.page = 0;
    },
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

      return pageOf(descending, this.page, this.pageSize).map(toRow);
    },
  },
};
</script>

<template>
  <div>
    <p v-if="description" class="gl-mb-3 gl-text-subtle" data-testid="description">
      {{ description }}
    </p>
    <div v-if="metricRows">
      <gl-skeleton-loader v-if="loading" />
      <bar-list-chart
        v-else-if="!displayConfigError"
        :data="metricRowsFor(barMetrics)"
        :value-labels="valueLabels"
        :color="color"
        :scale="scale"
      />
    </div>
    <dimension-routed-chart
      v-else
      display-type="barList"
      :fields="visibleFields"
      :loading="loading"
      :max-dimensions="$options.MAX_DIMENSIONS"
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
      <template #two-dimensions="{ dimensions, metric }">
        <two-dimensions-bar-list
          v-if="!displayConfigError"
          :data="data"
          :primary-dimension="dimensions[0]"
          :secondary-dimension="dimensions[1]"
          :metric="metric"
          :page="page"
          :page-size="pageSize"
          :max-series="maxSeries"
        />
      </template>
    </dimension-routed-chart>
    <gl-keyset-pagination
      v-if="pageCount > 1 && !loading && !displayConfigError"
      :has-previous-page="hasPreviousPage"
      :has-next-page="hasNextPage"
      class="gl-mt-3"
      @prev="page -= 1"
      @next="page += 1"
    />
  </div>
</template>
