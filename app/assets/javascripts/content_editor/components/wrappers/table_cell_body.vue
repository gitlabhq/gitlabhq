<script>
import TableCellBase from './table_cell_base.vue';

export default {
  name: 'TableCellBody',
  components: {
    TableCellBase,
  },
  props: {
    editor: {
      type: Object,
      required: true,
    },
    node: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <table-cell-base cell-type="td" v-bind="$props" />
</template>
