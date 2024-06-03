<script>
import { GlLoadingIcon, GlAlert, GlDrawer } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import WorkloadStats from './workload_stats.vue';
import WorkloadTable from './workload_table.vue';
import WorkloadDetails from './workload_details.vue';

export default {
  components: {
    GlLoadingIcon,
    GlAlert,
    GlDrawer,
    WorkloadStats,
    WorkloadTable,
    WorkloadDetails,
  },
  props: {
    loading: {
      type: Boolean,
      default: false,
      required: false,
    },
    errorMessage: {
      type: String,
      default: '',
      required: false,
    },
    stats: {
      type: Array,
      required: true,
    },
    items: {
      type: Array,
      required: true,
    },
    fields: {
      type: Array,
      required: false,
      default: undefined,
    },
  },
  data() {
    return {
      showDetailsDrawer: false,
      selectedItem: {},
      filterOption: '',
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    filteredItems() {
      if (!this.filterOption) return this.items;

      return this.items.filter((item) => item.status === this.filterOption);
    },
  },
  methods: {
    closeDetailsDrawer() {
      this.showDetailsDrawer = false;
    },
    onItemSelect(item) {
      this.selectedItem = item;
      this.showDetailsDrawer = true;
    },
    filterItems(status) {
      this.filterOption = status;
    },
  },
  DRAWER_Z_INDEX,
};
</script>
<template>
  <gl-loading-icon v-if="loading" />
  <gl-alert v-else-if="errorMessage" variant="danger" :dismissible="false" class="gl-mb-5">
    {{ errorMessage }}
  </gl-alert>
  <div v-else>
    <workload-stats :stats="stats" @select="filterItems" />
    <workload-table
      :items="filteredItems"
      :fields="fields"
      class="gl-mt-8"
      @select-item="onItemSelect"
      @remove-selection="closeDetailsDrawer"
    />

    <gl-drawer
      :open="showDetailsDrawer"
      :header-height="getDrawerHeaderHeight"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="closeDetailsDrawer"
    >
      <template #title>
        <h4 class="gl-font-bold gl-font-size-h2 gl-m-0 gl-break-anywhere">
          {{ selectedItem.name }}
        </h4>
      </template>
      <template #default>
        <workload-details :item="selectedItem" />
      </template>
    </gl-drawer>
  </div>
</template>
