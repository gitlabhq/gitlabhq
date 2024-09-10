<script>
import { GlTable, GlBadge, GlPagination, GlDisclosureDropdown, GlButton } from '@gitlab/ui';
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
    GlDisclosureDropdown,
    GlButton,
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
  },
  watch: {
    items() {
      this.currentPage = 1;
    },
  },
  methods: {
    selectItem(item) {
      this.selectedItem = item;
      this.$emit('select-item', item);
    },
    getActions(item) {
      const actions = item.actions || [];
      return actions.map((action) => {
        return {
          text: action.text,
          extraAttrs: { class: action.class },
          action: () => {
            this.$emit(action.name, item);
          },
        };
      });
    },
  },
  i18n: {
    emptyText: __('No results found'),
    actions: __('Actions'),
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
      show-empty
      stacked="md"
    >
      <template #cell(name)="{ item }">
        <gl-button variant="link" @click="selectItem(item)">{{ item.name }}</gl-button>
      </template>

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

      <template #cell(actions)="{ item }">
        <gl-disclosure-dropdown
          v-if="item.actions"
          :title="$options.i18n.actions"
          :items="getActions(item)"
          text-sr-only
          category="tertiary"
          no-caret
          icon="ellipsis_v"
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
