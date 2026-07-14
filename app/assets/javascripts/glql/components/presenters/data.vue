<script>
import { __, sprintf } from '~/locale';
import { DISPLAY_TYPES } from '../../constants';
import BarChartPresenter from './bar_chart.vue';
import ColumnChartPresenter from './column_chart.vue';
import LineChartPresenter from './line_chart.vue';
import ListPresenter from './list.vue';
import StatPresenter from './stat.vue';
import TablePresenter from './table.vue';

const SUPPORTED_DISPLAY_TYPES = Object.values(DISPLAY_TYPES);

export default {
  name: 'DataPresenter',
  components: {
    TablePresenter,
    ListPresenter,
    StatPresenter,
    ColumnChartPresenter,
    LineChartPresenter,
    BarChartPresenter,
  },
  props: {
    displayType: {
      required: true,
      type: String,
    },
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
      type: [Boolean, Number],
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
    isList() {
      return (
        this.displayType === DISPLAY_TYPES.LIST || this.displayType === DISPLAY_TYPES.ORDERED_LIST
      );
    },
    listType() {
      return this.displayType === DISPLAY_TYPES.LIST ? 'ul' : 'ol';
    },
    unsupportedDisplayTypeError() {
      if (SUPPORTED_DISPLAY_TYPES.includes(this.displayType)) return null;

      return sprintf(
        __(
          'Unknown display type: `%{displayType}`. Supported display types are: %{supportedDisplayTypes}.',
        ),
        {
          displayType: this.displayType,
          supportedDisplayTypes: SUPPORTED_DISPLAY_TYPES.map((type) => `\`${type}\``).join(', '),
        },
      );
    },
  },
  watch: {
    unsupportedDisplayTypeError: {
      immediate: true,
      handler(message) {
        if (message) this.$emit('error', new Error(message));
      },
    },
  },
  DISPLAY_TYPES,
};
</script>
<template>
  <table-presenter
    v-if="displayType === $options.DISPLAY_TYPES.TABLE"
    :data="data"
    :fields="fields"
    :loading="loading"
  />
  <list-presenter
    v-else-if="isList"
    :data="data"
    :fields="fields"
    :loading="loading"
    :list-type="listType"
  />
  <stat-presenter
    v-else-if="displayType === $options.DISPLAY_TYPES.STAT"
    :data="data"
    :fields="fields"
    :loading="loading"
    @error="$emit('error', $event)"
  />
  <column-chart-presenter
    v-else-if="displayType === $options.DISPLAY_TYPES.COLUMN_CHART"
    :data="data"
    :fields="fields"
    :loading="loading"
    :display-config="displayConfig"
    @error="$emit('error', $event)"
  />
  <line-chart-presenter
    v-else-if="displayType === $options.DISPLAY_TYPES.LINE_CHART"
    :data="data"
    :fields="fields"
    :loading="loading"
    @error="$emit('error', $event)"
  />
  <bar-chart-presenter
    v-else-if="displayType === $options.DISPLAY_TYPES.BAR_CHART"
    :data="data"
    :fields="fields"
    :loading="loading"
    :display-config="displayConfig"
    @error="$emit('error', $event)"
  />
</template>
