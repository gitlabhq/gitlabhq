<script>
import StorageUsageOverviewCard from './storage_usage_overview_card.vue';

export default {
  name: 'StorageUsageStatistics',
  components: {
    StorageUsageOverviewCard,
  },
  props: {
    usedStorage: {
      type: Number,
      required: false,
      default: 0,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
};
</script>
<template>
  <div>
    <h3 data-testid="overview-subtitle">{{ s__('UsageQuota|Namespace overview') }}</h3>
    <div class="gl-display-grid gl-md-grid-template-columns-2 gl-gap-5 gl-py-4">
      <storage-usage-overview-card
        :used-storage="usedStorage"
        :loading="loading"
        data-testid="namespace-usage-total"
      />
    </div>
  </div>
</template>
