<script>
import { GlAlert } from '@gitlab/ui';
import StorageUsageStatistics from 'ee_else_ce/usage_quotas/storage/components/storage_usage_statistics.vue';

export default {
  name: 'NamespaceStorageApp',
  components: {
    GlAlert,
    StorageUsageStatistics,
  },
  props: {
    namespaceLoadingError: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectsLoadingError: {
      type: Boolean,
      required: false,
      default: false,
    },
    isNamespaceStorageStatisticsLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    namespace: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    usedStorage() {
      return (
        // This is the coefficient adjusted forked repo size, only used in EE
        this.namespace.rootStorageStatistics?.costFactoredStorageSize ??
        // This is the actual storage size value, used in CE or when the above is disabled
        this.namespace.rootStorageStatistics?.storageSize
      );
    },
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="namespaceLoadingError || projectsLoadingError"
      variant="danger"
      :dismissible="false"
      class="gl-mt-4"
    >
      {{
        s__(
          'UsageQuota|An error occured while loading the storage usage details. Please refresh the page to try again.',
        )
      }}
    </gl-alert>
    <storage-usage-statistics
      :additional-purchased-storage-size="namespace.additionalPurchasedStorageSize"
      :used-storage="usedStorage"
      :loading="isNamespaceStorageStatisticsLoading"
    />

    <slot name="ee-storage-app"></slot>
  </div>
</template>
