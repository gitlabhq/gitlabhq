<script>
import { GlTable, GlBadge, GlPagination } from '@gitlab/ui';
import {
  WORKLOAD_STATUS_BADGE_VARIANTS,
  PAGE_SIZE,
  TABLE_HEADING_CLASSES,
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
          thClass: TABLE_HEADING_CLASSES,
          sortable: true,
        };
      });
    },
  },
  PAGE_SIZE,
  WORKLOAD_STATUS_BADGE_VARIANTS,
  TABLE_CELL_CLASSES: 'gl-p-2',
};
</script>

<template>
  <div class="gl-mt-8">
    <gl-table
      :items="items"
      :fields="tableFields"
      :per-page="$options.PAGE_SIZE"
      :current-page="currentPage"
      stacked="md"
      bordered
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
      :per-page="$options.PAGE_SIZE"
      :total-items="items.length"
      align="center"
      class="gl-mt-6"
    />
  </div>
</template>
