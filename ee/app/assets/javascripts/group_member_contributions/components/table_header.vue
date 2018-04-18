<script>
import { __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    columns: {
      type: Array,
      required: true,
    },
    sortOrders: {
      type: Object,
      required: true,
    },
  },
  data() {
    const columnIconMeta = this.columns.reduce(
      (acc, column) => ({
        ...acc,
        [column.name]: this.getColumnIconMeta(column.name, this.sortOrders),
      }),
      {},
    );

    return { columnIconMeta };
  },
  methods: {
    getColumnIconMeta(columnName, sortOrders) {
      const isAsc = sortOrders[columnName] > 0;
      return {
        sortIcon: isAsc ? 'angle-up' : 'angle-down',
        iconTooltip: isAsc ? __('Ascending') : __('Descending'),
      };
    },
    getColumnSortIcon(columnName) {
      return this.columnIconMeta[columnName].sortIcon;
    },
    getColumnSortTooltip(columnName) {
      return this.columnIconMeta[columnName].iconTooltip;
    },
    onColumnClick(columnName) {
      this.$emit('onColumnClick', columnName);
      this.columnIconMeta[columnName] = this.getColumnIconMeta(columnName, this.sortOrders);
    },
  },
};
</script>

<template>
  <thead>
    <tr>
      <th
        v-for="(column, index) in columns"
        :key="index"
        class="header"
        :title="getColumnSortTooltip(column.name)"
        @click="onColumnClick(column.name)"
      >
        {{ column.text }}
        <icon
          :size="12"
          :name="getColumnSortIcon(column.name)"
        />
      </th>
    </tr>
  </thead>
</template>
