<script>
import { __ } from '~/locale';
import { DISPLAY_TYPES } from '../../constants';
import ListPresenter from './list.vue';
import TablePresenter from './table.vue';
import ColumnChart from './column_chart.vue';

export default {
  name: 'DataPresenter',
  components: {
    TablePresenter,
    ListPresenter,
    ColumnChart,
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
    aggregate: {
      required: false,
      type: Array,
      default: null,
    },
    groupBy: {
      required: false,
      type: Array,
      default: null,
    },
    loading: {
      required: false,
      type: [Boolean, Number],
      default: false,
    },
  },
  DISPLAY_TYPES,
  mounted() {
    if (
      this.displayType === this.$options.DISPLAY_TYPES.COLUMN_CHART &&
      !(this.aggregate?.length > 0 && this.groupBy?.length > 0)
    ) {
      this.$emit('error', __('Columns charts require an aggregation to be defined'));
    }
  },
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
    v-else-if="
      displayType === $options.DISPLAY_TYPES.LIST ||
      displayType === $options.DISPLAY_TYPES.ORDERED_LIST
    "
    :data="data"
    :fields="fields"
    :loading="loading"
    :list-type="displayType === $options.DISPLAY_TYPES.LIST ? 'ul' : 'ol'"
  />
  <column-chart
    v-else-if="displayType === $options.DISPLAY_TYPES.COLUMN_CHART"
    :data="data"
    :aggregate="aggregate"
    :group-by="groupBy"
    :loading="loading"
  />
</template>
