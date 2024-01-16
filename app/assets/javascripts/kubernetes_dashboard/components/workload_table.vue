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
  },
  methods: {
    selectItem(item) {
      this.$emit('select-item', item);
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
  <div class="gl-mt-8">
    <gl-table
      :items="items"
      :fields="tableFields"
      :per-page="$options.PAGE_SIZE"
      :current-page="currentPage"
      :empty-text="$options.i18n.emptyText"
      tbody-tr-class="gl-hover-cursor-pointer"
      show-empty
      stacked="md"
      hover
      @row-clicked="selectItem"
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
