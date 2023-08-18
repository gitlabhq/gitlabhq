<script>
import { GlAlert, GlButton, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { updateRepositorySize } from '~/api/projects_api';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import {
  ERROR_MESSAGE,
  LEARN_MORE_LABEL,
  USAGE_QUOTAS_LABEL,
  TOTAL_USAGE_TITLE,
  TOTAL_USAGE_SUBTITLE,
  TOTAL_USAGE_DEFAULT_TEXT,
  HELP_LINK_ARIA_LABEL,
  RECALCULATE_REPOSITORY_LABEL,
  PROJECT_STORAGE_TYPES,
  NAMESPACE_STORAGE_TYPES,
  usageQuotasHelpPaths,
  storageTypeHelpPaths,
} from '../constants';
import getProjectStorageStatistics from '../queries/project_storage.query.graphql';
import { getStorageTypesFromProjectStatistics, descendingStorageUsageSort } from '../utils';
import UsageGraph from './usage_graph.vue';
import ProjectStorageDetail from './project_storage_detail.vue';

export default {
  name: 'ProjectStorageApp',
  components: {
    GlAlert,
    GlButton,
    GlLink,
    GlLoadingIcon,
    UsageGraph,
    ProjectStorageDetail,
  },
  inject: ['projectPath'],
  apollo: {
    project: {
      query: getProjectStorageStatistics,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      error() {
        this.error = ERROR_MESSAGE;
      },
    },
  },
  data() {
    return {
      project: {},
      error: '',
      loadingRecalculateSize: false,
    };
  },
  computed: {
    isStatisticsEmpty() {
      return this.project?.statistics == null;
    },
    totalUsage() {
      if (!this.isStatisticsEmpty) {
        return numberToHumanSize(this.project?.statistics?.storageSize, 1);
      }

      return TOTAL_USAGE_DEFAULT_TEXT;
    },
    projectStorageTypes() {
      if (this.isStatisticsEmpty) {
        return [];
      }

      return getStorageTypesFromProjectStatistics(
        PROJECT_STORAGE_TYPES,
        this.project?.statistics,
        this.project?.statisticsDetailsPaths,
        storageTypeHelpPaths,
      ).sort(descendingStorageUsageSort('value'));
    },
    namespaceStorageTypes() {
      if (this.isStatisticsEmpty) {
        return [];
      }

      return getStorageTypesFromProjectStatistics(
        NAMESPACE_STORAGE_TYPES,
        this.project?.statistics,
        this.project?.statisticsDetailsPaths,
        storageTypeHelpPaths,
      );
    },
  },
  methods: {
    clearError() {
      this.error = '';
    },
    helpLinkAriaLabel(linkTitle) {
      return sprintf(HELP_LINK_ARIA_LABEL, {
        linkTitle,
      });
    },
    async postRecalculateSize() {
      const alertEl = document.querySelector('.js-recalculation-started-alert');

      this.loadingRecalculateSize = true;

      await updateRepositorySize(this.projectPath);

      this.loadingRecalculateSize = false;
      alertEl?.classList.remove('gl-display-none');
    },
  },
  usageQuotasHelpPaths,
  LEARN_MORE_LABEL,
  USAGE_QUOTAS_LABEL,
  TOTAL_USAGE_TITLE,
  TOTAL_USAGE_SUBTITLE,
  RECALCULATE_REPOSITORY_LABEL,
};
</script>
<template>
  <gl-loading-icon v-if="$apollo.queries.project.loading" class="gl-mt-5" size="lg" />
  <gl-alert v-else-if="error" variant="danger" @dismiss="clearError">
    {{ error }}
  </gl-alert>
  <div v-else>
    <div class="gl-pt-5 gl-px-3">
      <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
        <div>
          <h2 class="gl-m-0 gl-font-lg gl-font-weight-bold">{{ $options.TOTAL_USAGE_TITLE }}</h2>
          <p class="gl-m-0 gl-text-gray-400">
            {{ $options.TOTAL_USAGE_SUBTITLE }}
            <gl-link
              :href="$options.usageQuotasHelpPaths.usageQuotas"
              target="_blank"
              :aria-label="helpLinkAriaLabel($options.USAGE_QUOTAS_LABEL)"
              >{{ $options.LEARN_MORE_LABEL }}</gl-link
            >
          </p>
        </div>
        <p class="gl-m-0 gl-font-size-h-display gl-font-weight-bold" data-testid="total-usage">
          {{ totalUsage }}
        </p>
      </div>
    </div>
    <div v-if="!isStatisticsEmpty" class="gl-w-full">
      <usage-graph :root-storage-statistics="project.statistics" :limit="0" />
    </div>
    <div class="gl-w-full gl-my-5">
      <gl-button
        :loading="loadingRecalculateSize"
        category="secondary"
        @click="postRecalculateSize"
      >
        {{ $options.RECALCULATE_REPOSITORY_LABEL }}
      </gl-button>
    </div>
    <project-storage-detail
      :storage-types="projectStorageTypes"
      data-testid="usage-quotas-project-usage-details"
    />
    <div>
      <h2 class="gl-mb-2 gl-mt-5 gl-font-lg gl-font-weight-bold">
        {{ s__('UsageQuota|Namespace entities') }}
      </h2>

      <project-storage-detail
        :storage-types="namespaceStorageTypes"
        data-testid="usage-quotas-namespace-usage-details"
      />
    </div>
  </div>
</template>
