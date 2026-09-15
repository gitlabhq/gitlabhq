<script>
import { COLUMN_TITLE } from '../constants';
import WorkItemTableCell from './work_item_table_cell.vue';
import WorkItemTitleCell from './work_item_title_cell.vue';

export default {
  name: 'WorkItemTableRow',
  components: {
    WorkItemTableCell,
    WorkItemTitleCell,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    columns: {
      type: Array,
      required: true,
    },
    rootPageFullPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    // Decides element and role once per column, so the template doesn't re-derive them
    // per cell. The title names the row, so it is the row's header cell, not a data cell.
    normalizedColumns() {
      return this.columns.map((column) => {
        const isTitle = column.key === COLUMN_TITLE;
        return { ...column, tag: isTitle ? 'th' : 'td', scope: isTitle ? 'row' : null, isTitle };
      });
    },
  },
};
</script>

<template>
  <tr class="gl-border-b last:gl-border-b-0 hover:gl-bg-subtle" data-testid="work-item-table-row">
    <component
      :is="column.tag"
      v-for="column in normalizedColumns"
      :key="column.key"
      :scope="column.scope"
      class="gl-border-r gl-truncate gl-px-4 gl-py-3 gl-text-left gl-align-middle gl-font-normal last:gl-border-r-0"
    >
      <work-item-title-cell v-if="column.isTitle" :item="item" />
      <work-item-table-cell
        v-else
        :item="item"
        :column-key="column.key"
        :root-page-full-path="rootPageFullPath"
      />
    </component>
  </tr>
</template>
