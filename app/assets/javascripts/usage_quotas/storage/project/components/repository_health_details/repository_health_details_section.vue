<script>
import { GlLoadingIcon, GlButton, GlEmptyState } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getProjectRepositoryHealth } from '~/rest_api';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import RepositoryHealthDetailsHeader from './repository_health_details_header.vue';
import RepositoryHealthDetailsStorageBreakdown from './repository_health_details_storage_breakdown.vue';
import RepositoryHealthDetailsPerformanceOptimizations from './repository_health_details_performance_optimizations.vue';
import RepositoryHealthDetailsMaintenanceStatus from './repository_health_details_maintenance_status.vue';

export default {
  name: 'RepositoryHealthDetailsSection',
  components: {
    GlLoadingIcon,
    GlButton,
    GlEmptyState,
    RepositoryHealthDetailsHeader,
    RepositoryHealthDetailsStorageBreakdown,
    RepositoryHealthDetailsPerformanceOptimizations,
    RepositoryHealthDetailsMaintenanceStatus,
  },
  props: {
    repository: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      loading: false,
      healthDetails: null,
    };
  },
  computed: {
    projectId() {
      if (!this.repository?.project) {
        return null;
      }

      return getIdFromGraphQLId(this.repository.project.id);
    },
  },
  created() {
    this.fetchRepositoryHealth();
  },
  methods: {
    async fetchRepositoryHealth(params = {}) {
      if (!this.projectId) {
        return;
      }

      try {
        this.loading = true;
        this.healthDetails = convertObjectPropsToCamelCase(
          (await getProjectRepositoryHealth(this.projectId, params))?.data,
          { deep: true },
        );
      } catch (e) {
        // 404 is the default response if a Health Report hasn't been generated yet.
        if (e.response?.status === 404) return;

        createAlert({
          message: s__('UsageQuota|Failed to fetch repository health, try again later.'),
          captureError: true,
          error: e,
        });
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <section class="gl-border gl-rounded-lg gl-bg-neutral-10 gl-px-6 gl-py-5 lg:gl-ml-7">
    <template v-if="!projectId">
      <p class="gl-mb-0">{{ s__('UsageQuota|Failed to parse Project ID from Repository.') }}</p>
    </template>
    <gl-loading-icon v-else-if="loading" />
    <gl-empty-state
      v-else-if="!healthDetails"
      :title="s__('UsageQuota|Repository Health report was not found')"
      :description="
        s__('UsageQuota|You can generate a new report at any time by clicking the button below.')
      "
      illustration-name="status-nothing-md"
    >
      <template #actions>
        <gl-button variant="confirm" @click="fetchRepositoryHealth({ generate: true })">{{
          s__('UsageQuota|Generate Report')
        }}</gl-button>
      </template>
    </gl-empty-state>
    <template v-else>
      <repository-health-details-header
        :health-details="healthDetails"
        @regenerate-report="fetchRepositoryHealth({ generate: true })"
      />
      <repository-health-details-storage-breakdown :health-details="healthDetails" />
      <repository-health-details-performance-optimizations :health-details="healthDetails" />
      <repository-health-details-maintenance-status :health-details="healthDetails" />
    </template>
  </section>
</template>
