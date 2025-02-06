<script>
import { GlAlert, GlKeysetPagination } from '@gitlab/ui';
import { captureException } from '~/ci/runner/sentry_utils';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import NamespaceStorageQuery from 'ee_else_ce/usage_quotas/storage/namespace/queries/namespace_storage.query.graphql';
import ProjectListStorageQuery from 'ee_else_ce/usage_quotas/storage/namespace/queries/project_list_storage.query.graphql';
import StorageUsageStatistics from 'ee_else_ce/usage_quotas/storage/namespace/components/storage_usage_statistics.vue';
import SearchAndSortBar from '~/usage_quotas/components/search_and_sort_bar/search_and_sort_bar.vue';
import { parseGetStorageResults } from '../utils';
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
  inject: [
    'namespaceId',
    'namespacePath',
    'helpLinks',
    'defaultPerPage',
    'userNamespace',
    'customSortKey',
  ],
  apollo: {
    namespace: {
      query: NamespaceStorageQuery,
      variables() {
        return {
          fullPath: this.namespacePath,
        };
      },
      update: parseGetStorageResults,
      error(error) {
        this.namespaceLoadingError = true;
        captureException({ error, component: this.$options.name });
      },
    },
    projects: {
      query: ProjectListStorageQuery,
      variables() {
        return {
          fullPath: this.namespacePath,
          searchTerm: this.searchTerm,
          first: this.defaultPerPage,
          sortKey: this.sortKey,
        };
      },
      update(data) {
        return data.namespace.projects;
      },
      error(error) {
        this.projectsLoadingError = true;
        captureException({ error, component: this.$options.name });
      },
    },
  },
  data() {
    return {
      namespace: {},
      projects: null,
      searchTerm: '',
      namespaceLoadingError: false,
      projectsLoadingError: false,
      sortKey: this.customSortKey ?? 'STORAGE_SIZE_DESC',
      initialSortBy: this.customSortKey ? null : 'storage',
      sortableFields: { storage: !this.customSortKey },
    };
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
    onSearch(searchTerm) {
      if (searchTerm?.length < 3) {
        // NOTE: currently the API doesn't handle strings of length < 3,
        // returning an empty list as a result of such searches. So here we
        // substitute short search terms with empty string to simulate default
        // "fetch all" behaviour.
        this.searchTerm = '';
      } else {
        this.searchTerm = searchTerm;
      }
    },
    onSortChanged({ sortBy, sortDesc }) {
      if (!this.sortableFields[sortBy]) {
        return;
      }

      const sortDir = sortDesc ? 'desc' : 'asc';
      const sortKey = `${convertToSnakeCase(sortBy)}_size_${sortDir}`.toUpperCase();
      this.sortKey = sortKey;
    },
    fetchMoreProjects(vars) {
      this.$apollo.queries.projects.fetchMore({
        variables: {
          fullPath: this.namespacePath,
          ...vars,
        },
        updateQuery(previousResult, { fetchMoreResult }) {
          return fetchMoreResult;
        },
      });
    },
    onPrev(before) {
      if (this.pageInfo?.hasPreviousPage) {
        this.fetchMoreProjects({ before, last: this.defaultPerPage, first: undefined });
      }
    },
    onNext(after) {
      if (this.pageInfo?.hasNextPage) {
        this.fetchMoreProjects({ after, first: this.defaultPerPage });
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
      :loading="$apollo.queries.namespace.loading"
    />
    <h2 class="gl-heading-2 gl-mb-3 gl-mt-5" data-testid="breakdown-subtitle">
      {{ s__('UsageQuota|Storage usage breakdown') }}
    </h2>
    <dependency-proxy-usage
      v-if="!userNamespace"
      :dependency-proxy-total-size="dependencyProxyTotalSize"
      :loading="$apollo.queries.namespace.loading"
    />
    <container-registry-usage
      :container-registry-size="containerRegistrySize"
      :container-registry-size-is-estimated="containerRegistrySizeIsEstimated"
      :loading="$apollo.queries.namespace.loading"
    />

    <section class="gl-mt-5">
      <div class="gl-flex gl-bg-subtle gl-p-5">
        <search-and-sort-bar
          :namespace="namespaceId"
          :search-input-placeholder="__('Search')"
          @onFilter="onSearch"
        />
      </div>
      <project-list
        :projects="projectList"
        :namespace="namespace"
        :is-loading="$apollo.queries.projects.loading"
        :help-links="helpLinks"
        :sort-by="initialSortBy"
        :sortable-fields="sortableFields"
        @sortChanged="onSortChanged"
      />
      <div class="gl-mt-5 gl-flex gl-justify-center">
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
