<script>
import { GlAlert, GlKeysetPagination } from '@gitlab/ui';
import StorageUsageStatistics from 'ee_else_ce/usage_quotas/storage/components/storage_usage_statistics.vue';
import SearchAndSortBar from '~/usage_quotas/components/search_and_sort_bar/search_and_sort_bar.vue';
import DependencyProxyUsage from './dependency_proxy_usage.vue';
import ContainerRegistryUsage from './container_registry_usage.vue';
import ProjectList from './project_list.vue';

export default {
  name: 'NamespaceStorageApp',
  components: {
    GlAlert,
    GlKeysetPagination,
    StorageUsageStatistics,
    DependencyProxyUsage,
    ContainerRegistryUsage,
    SearchAndSortBar,
    ProjectList,
  },
  inject: ['userNamespace', 'namespaceId', 'helpLinks', 'defaultPerPage'],
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
    isNamespaceProjectsLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    namespace: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    projects: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    initialSortBy: {
      type: String,
      required: false,
      default: 'storage',
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
    dependencyProxyTotalSize() {
      return this.namespace.rootStorageStatistics?.dependencyProxySize ?? 0;
    },
    containerRegistrySize() {
      return this.namespace.rootStorageStatistics?.containerRegistrySize ?? 0;
    },
    containerRegistrySizeIsEstimated() {
      return this.namespace.rootStorageStatistics?.containerRegistrySizeIsEstimated ?? false;
    },
    projectList() {
      return this.projects?.nodes ?? [];
    },
    pageInfo() {
      return this.projects?.pageInfo;
    },
    showPagination() {
      return Boolean(this.pageInfo?.hasPreviousPage || this.pageInfo?.hasNextPage);
    },
  },
  methods: {
    onPrev(before) {
      if (this.pageInfo?.hasPreviousPage) {
        this.$emit('fetch-more-projects', { before, last: this.defaultPerPage, first: undefined });
      }
    },
    onNext(after) {
      if (this.pageInfo?.hasNextPage) {
        this.$emit('fetch-more-projects', { after, first: this.defaultPerPage });
      }
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
    <h3 data-testid="breakdown-subtitle">
      {{ s__('UsageQuota|Storage usage breakdown') }}
    </h3>
    <dependency-proxy-usage
      v-if="!userNamespace"
      :dependency-proxy-total-size="dependencyProxyTotalSize"
      :loading="isNamespaceStorageStatisticsLoading"
    />
    <container-registry-usage
      :container-registry-size="containerRegistrySize"
      :container-registry-size-is-estimated="containerRegistrySizeIsEstimated"
      :loading="isNamespaceStorageStatisticsLoading"
    />

    <section class="gl-mt-5">
      <div class="gl-bg-gray-10 gl-p-5 gl-display-flex">
        <search-and-sort-bar
          :namespace="namespaceId"
          :search-input-placeholder="__('Search')"
          @onFilter="
            (searchTerm) => {
              $emit('search', searchTerm);
            }
          "
        />
      </div>
      <project-list
        :projects="projectList"
        :is-loading="isNamespaceProjectsLoading"
        :help-links="helpLinks"
        :sort-by="initialSortBy"
        :sort-desc="true"
        @sortChanged="
          ($event) => {
            $emit('sort-changed', $event);
          }
        "
      />
      <div class="gl-display-flex gl-justify-content-center gl-mt-5">
        <gl-keyset-pagination
          v-if="showPagination"
          v-bind="pageInfo"
          @prev="onPrev"
          @next="onNext"
        />
      </div>
    </section>
  </div>
</template>
