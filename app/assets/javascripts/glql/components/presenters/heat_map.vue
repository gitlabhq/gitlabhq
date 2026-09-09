<script>
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

export default {
  name: 'HeatMapPresenter',
  components: { DimensionRoutedChart, FormattedTooltipContent, HeatMapChart },
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
    description() {
      return this.displayConfig?.description;
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

      return bars.flatMap(({ name, data }) =>
        data.map((value, index) => ({
          column: formatColumn(groups[index]),
          row: name,
          value,
        })),
      );
    },
    // Compact in the cell so a value fits a narrow column, full digits in the
    // tooltip where there is room. The chart cannot name its own axes, so the
    // description for assistive technology is supplied here too.
    optionsFor(dimensions, metric) {
      return {
        formatValue: axisFormatterFor(baseFieldKeyOf(metric)),
        aria: { label: { description: this.ariaDescription(dimensions, metric) } },
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
    ariaDescription(dimensions, metric) {
      return sprintf(__('Heat map of %{metric} by %{columns} and %{rows}.'), {
        metric: labelWithParameter(metric),
        columns: labelWithParameter(dimensions[0]),
        rows: labelWithParameter(dimensions[1]),
      });
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
        <heat-map-chart
          :data="cellsFor(dimensions, metric)"
          :options="optionsFor(dimensions, metric)"
        >
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
