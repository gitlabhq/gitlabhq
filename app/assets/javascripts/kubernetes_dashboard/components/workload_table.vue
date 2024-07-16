<script>
import { GlTable, GlBadge, GlPagination } from '@gitlab/ui';
import { __ } from '~/locale';
import PodLogsButton from '~/environments/environment_details/components/kubernetes/pod_logs_button.vue';
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
    PodLogsButton,
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
          sortable: field.sortable !== false,
        };
      });
    },
  },
  watch: {
    items() {
      this.currentPage = 1;
    },
  },
  methods: {
    selectItem(item) {
      const selectedItem = item[0];

      if (selectedItem) {
        this.$emit('select-item', selectedItem);
      } else {
        this.$emit('remove-selection');
      }
    },
  },
  i18n: {
    emptyText: __('No results found'),
  },
  WORKLOAD_STATUS_BADGE_VARIANTS,
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
      hover
      selectable
      select-mode="single"
      selected-variant="primary"
      show-empty
      stacked="md"
      @row-selected="selectItem"
    >
      <template #cell(status)="{ item: { status } }">
        <gl-badge :variant="$options.WORKLOAD_STATUS_BADGE_VARIANTS[status]" class="gl-ml-2">{{
          status
        }}</gl-badge>
      </template>

      <template #cell(logs)="{ item: { name, namespace, containers } }">
        <pod-logs-button
          v-if="containers"
          :namespace="namespace"
          :pod-name="name"
          :containers="containers"
        />
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
