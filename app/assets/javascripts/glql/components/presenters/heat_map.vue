<script>
import { maxBy } from 'lodash-es';
import { __, sprintf } from '~/locale';
import HeatMapChart from '~/analytics/analytics_dashboards/components/visualizations/heat_map_chart.vue';
import {
  baseFieldKeyOf,
  buildStackedByDimension,
  dimensionLabelFormatter,
  labelWithParameter,
} from '../../utils/chart_data';
import { axisFormatterFor, formatterFor } from '../../utils/value_format';
import { DISPLAY_TYPES } from '../../constants';
import DimensionRoutedChart from './chart/dimension_routed_chart.vue';
import FormattedTooltipContent from './chart/formatted_tooltip_content.vue';

// A capped axis keeps its busiest entries and drops the rest, so the colour
// ramp spans the values on screen. The panel title has to say it is capped.
// Ties break on the label, so which entry survives the cap does not depend on
// the order the query happened to return.
const largestFirst = (entries, max) =>
  [...entries].sort((a, b) => b.total - a.total || a.label.localeCompare(b.label)).slice(0, max);

export default {
  name: 'HeatMapPresenter',
  components: { DimensionRoutedChart, FormattedTooltipContent, HeatMapChart },
  inject: {
    getVisualizationTitle: { default: () => () => '' },
  },
  props: {
    data: {
      required: false,
      type: Object,
      default: () => ({ nodes: [] }),
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
  },
  emits: { error: null },
  computed: {
    visualizationTitle() {
      return this.getVisualizationTitle();
    },
    description() {
      return this.displayConfig?.description;
    },
    // A dense grid can cap either axis, keeping the busiest entries.
    maxColumns() {
      return this.axisCap(this.displayConfig?.maxColumns);
    },
    maxRows() {
      return this.axisCap(this.displayConfig?.maxRows);
    },
  },
  methods: {
    // The chart takes semantic cells; turning a GLQL result into them is this
    // presenter's job.
    cellsFor(dimensions, metric) {
      const [columnDimension, rowDimension] = dimensions;
      const { groups, bars } = buildStackedByDimension({
        nodes: this.data.nodes,
        primaryDim: columnDimension,
        secondaryDim: rowDimension,
        metric,
      });
      const formatColumn = dimensionLabelFormatter(this.data.nodes, columnDimension);

      const columns = this.cappedAxis(
        groups.map((group, index) => ({
          label: formatColumn(group),
          index,
          total: bars.reduce((sum, { data }) => sum + data[index], 0),
        })),
        this.maxColumns,
      );
      const rows = this.cappedAxis(
        bars.map(({ name, data }, index) => ({
          label: name,
          index,
          total: data.reduce((sum, value) => sum + value, 0),
        })),
        this.maxRows,
      );

      return rows.flatMap((row) =>
        columns.map((column) => ({
          column: column.label,
          row: row.label,
          value: bars[row.index].data[column.index],
        })),
      );
    },
    axisCap(value) {
      const max = Number(value);

      return Number.isInteger(max) && max > 0 ? max : null;
    },
    cappedAxis(entries, max) {
      return max ? largestFirst(entries, max) : entries;
    },
    // Compact in the cell so a value fits a narrow column, full digits in the
    // tooltip where there is room. The chart cannot name its own axes, so the
    // description for assistive technology is supplied here too, from the same cells.
    chartPropsFor(dimensions, metric) {
      const cells = this.cellsFor(dimensions, metric);

      return {
        data: cells,
        options: {
          formatValue: axisFormatterFor(baseFieldKeyOf(metric)),
          aria: { label: { description: this.ariaDescription(dimensions, metric, cells) } },
        },
      };
    },
    // Labelled from the metric, so a query alias renames it.
    tooltipContent(metric, value) {
      return { [labelWithParameter(metric)]: { value, color: '' } };
    },
    formatTooltipValue(metric) {
      const format = formatterFor(baseFieldKeyOf(metric));

      return (_label, value) => format(value);
    },
    ariaDescription(dimensions, metric, cells) {
      const title = this.visualizationTitle;
      const axes = {
        metric: labelWithParameter(metric),
        columns: labelWithParameter(dimensions[0]),
        rows: labelWithParameter(dimensions[1]),
      };
      // Separate strings rather than prepending the title, so translators see its punctuation.
      const shape = title
        ? sprintf(__('%{title}. Heat map of %{metric} by %{columns} and %{rows}.'), {
            ...axes,
            title,
          })
        : sprintf(__('Heat map of %{metric} by %{columns} and %{rows}.'), axes);
      const highest = maxBy(cells, 'value');
      const peak = highest
        ? sprintf(__('Highest is %{value} for %{column} and %{row}.'), {
            value: formatterFor(baseFieldKeyOf(metric))(highest.value),
            row: highest.row,
            column: highest.column,
          })
        : '';

      return [shape, peak].filter(Boolean).join(' ');
    },
  },
  DISPLAY_TYPES,
};
</script>

<template>
  <div>
    <p v-if="description" class="gl-mb-3 gl-text-subtle">{{ description }}</p>
    <dimension-routed-chart
      :display-type="$options.DISPLAY_TYPES.HEAT_MAP"
      :fields="fields"
      :loading="loading"
      :min-dimensions="2"
      :max-dimensions="2"
      @error="$emit('error', $event)"
    >
      <template #two-dimensions="{ dimensions, metric }">
        <heat-map-chart v-bind="chartPropsFor(dimensions, metric)">
          <template #tooltip-content="{ value }">
            <formatted-tooltip-content
              :content="tooltipContent(metric, value)"
              :format-value="formatTooltipValue(metric)"
            />
          </template>
        </heat-map-chart>
      </template>
    </dimension-routed-chart>
  </div>
</template>
