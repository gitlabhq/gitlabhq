<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import WorkloadStats from './workload_stats.vue';
import WorkloadTable from './workload_table.vue';
import WorkloadDetailsDrawer from './workload_details_drawer.vue';

export default {
  components: {
    GlLoadingIcon,
    GlAlert,
    WorkloadStats,
    WorkloadTable,
    WorkloadDetailsDrawer,
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
      filterOption: '',
    };
  },
  computed: {
    filteredItems() {
      if (!this.filterOption) return this.items;

      return this.items.filter((item) => item.status === this.filterOption);
    },
  },
  methods: {
    onItemSelect(item) {
      this.$refs.detailsDrawer?.toggle(item);
    },
    filterItems(status) {
      this.filterOption = status;
    },
  },
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
    />
    <workload-details-drawer ref="detailsDrawer" />
  </div>
</template>
