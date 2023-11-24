<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import WorkloadStats from './workload_stats.vue';
import WorkloadTable from './workload_table.vue';

export default {
  components: {
    GlLoadingIcon,
    GlAlert,
    WorkloadStats,
    WorkloadTable,
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
};
</script>
<template>
  <gl-loading-icon v-if="loading" />
  <gl-alert v-else-if="errorMessage" variant="danger" :dismissible="false" class="gl-mb-5">
    {{ errorMessage }}
  </gl-alert>
  <div v-else>
    <workload-stats :stats="stats" />
    <workload-table :items="items" />
  </div>
</template>
