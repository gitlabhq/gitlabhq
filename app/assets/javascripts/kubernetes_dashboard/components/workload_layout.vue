<script>
import { GlLoadingIcon, GlAlert, GlDrawer } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
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
  },
  data() {
    return {
      showDetailsDrawer: false,
      selectedItem: {},
    };
  },
  methods: {
    closeDetailsDrawer() {
      this.showDetailsDrawer = false;
    },
    onItemSelect(item) {
      this.selectedItem = item;
      this.showDetailsDrawer = true;
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
    <workload-stats :stats="stats" />
    <workload-table :items="items" @select-item="onItemSelect" />

    <gl-drawer
      :open="showDetailsDrawer"
      header-height="calc(var(--top-bar-height) + var(--performance-bar-height))"
      :z-index="$options.DRAWER_Z_INDEX"
      @close="closeDetailsDrawer"
    >
      <template #title>
        <h4 class="gl-font-weight-bold gl-font-size-h2 gl-m-0">{{ selectedItem.name }}</h4>
      </template>
      <template #default>
        <workload-details :item="selectedItem" />
      </template>
    </gl-drawer>
  </div>
</template>
