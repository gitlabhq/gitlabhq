<script>
import { GlTable, GlBadge, GlPagination } from '@gitlab/ui';
import { __ } from '~/locale';
import {
  WORKLOAD_STATUS_BADGE_VARIANTS,
  PAGE_SIZE,
  DEFAULT_WORKLOAD_TABLE_FIELDS,
} from '../constants';

export default {
  components: {
    GlTable,
    GlBadge,
    GlPagination,
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
    fields: {
      type: Array,
      default: () => DEFAULT_WORKLOAD_TABLE_FIELDS,
      required: false,
    },
    pageSize: {
      type: Number,
      default: PAGE_SIZE,
      required: false,
    },
    rowClickable: {
      type: Boolean,
      default: true,
      required: false,
    },
  },
  data() {
    return {
      currentPage: 1,
    };
  },
  computed: {
    tableFields() {
      return this.fields.map((field) => {
        return {
          ...field,
          sortable: true,
        };
      });
    },
    tableRowClass() {
      return this.rowClickable ? 'gl-hover-cursor-pointer' : '';
    },
  },
  methods: {
    selectItem(item) {
      const selectedItem = item[0];

      if (selectedItem) {
        this.$emit('select-item', selectedItem);
      }
    },
  },
  i18n: {
    emptyText: __('No results found'),
  },
  PAGE_SIZE,
  WORKLOAD_STATUS_BADGE_VARIANTS,
  TABLE_CELL_CLASSES: 'gl-p-2',
};
</script>

<template>
  <div>
    <gl-table
      :items="items"
      :fields="tableFields"
      :per-page="pageSize"
      :current-page="currentPage"
      :empty-text="$options.i18n.emptyText"
      :tbody-tr-class="tableRowClass"
      :hover="rowClickable"
      :selectable="rowClickable"
      :no-select-on-click="!rowClickable"
      select-mode="single"
      selected-variant="primary"
      show-empty
      stacked="md"
      @row-selected="selectItem"
    >
      <template #cell(status)="{ item: { status } }">
        <gl-badge
          :variant="$options.WORKLOAD_STATUS_BADGE_VARIANTS[status]"
          size="sm"
          class="gl-ml-2"
          >{{ status }}</gl-badge
        >
      </template>
    </gl-table>

    <gl-pagination
      v-model="currentPage"
      :per-page="pageSize"
      :total-items="items.length"
      align="center"
      class="gl-mt-6"
    />
  </div>
</template>
