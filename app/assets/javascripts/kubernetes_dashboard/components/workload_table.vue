<script>
import { GlTable, GlBadge, GlPagination, GlButton, GlTooltipDirective } from '@gitlab/ui';
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
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
      selectedItem: null,
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
    totalPages() {
      return Math.ceil(this.items.length / this.pageSize);
    },
  },
  watch: {
    items() {
      if (this.currentPage > this.totalPages && this.totalPages > 0) {
        this.currentPage = this.totalPages;
      }
    },
  },
  methods: {
    selectItem(item) {
      this.selectedItem = item;
      this.$emit('select-item', item);
    },
    getDeleteAction(item) {
      const actions = item.actions || [];

      return actions.find((action) => action.name === 'delete-pod') || null;
    },
    // eslint-disable-next-line vue/no-unused-properties -- triggered from outside of the component
    resetPagination() {
      this.currentPage = 1;
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
      primary-key="name"
      show-empty
      stacked="lg"
    >
      <template #cell(name)="{ item }">
        <gl-button
          :title="item.name"
          class="gl-max-w-full gl-truncate"
          variant="link"
          @click="selectItem(item)"
          >{{ item.name }}</gl-button
        >
      </template>

      <template #cell(status)="{ item: { status, statusText, statusTooltip } }">
        <gl-badge
          v-gl-tooltip
          :variant="$options.WORKLOAD_STATUS_BADGE_VARIANTS[status]"
          :title="statusTooltip"
          :tabindex="statusTooltip ? '0' : undefined"
        >
          {{ statusText || status }}
        </gl-badge>
      </template>

      <template #cell(actions)="{ item }">
        <div class="gl-flex gl-items-center gl-justify-end gl-gap-4 @lg/panel:gl-justify-between">
          <pod-logs-button
            v-if="item.containers"
            :namespace="item.namespace"
            :pod-name="item.name"
            :containers="item.containers"
          />
          <gl-button
            v-if="getDeleteAction(item)"
            icon="remove"
            size="small"
            variant="danger"
            category="tertiary"
            data-testid="delete-action-button"
            :aria-label="getDeleteAction(item).text"
            @click="$emit(getDeleteAction(item).name, item)"
          />
        </div>
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
