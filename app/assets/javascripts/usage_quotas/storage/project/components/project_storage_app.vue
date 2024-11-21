<script>
import { GlAlert, GlButton, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { getPreferredLocales, sprintf, s__, __ } from '~/locale';
import { updateRepositorySize } from '~/api/projects_api';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import SectionedPercentageBar from '~/usage_quotas/components/sectioned_percentage_bar.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getProjectStorageStatistics from 'ee_else_ce/usage_quotas/storage/project/queries/project_storage.query.graphql';
import getCostFactoredProjectStorageStatistics from 'ee_else_ce/usage_quotas/storage/project/queries/cost_factored_project_storage.query.graphql';
import {
  PROJECT_STORAGE_TYPES,
  NAMESPACE_STORAGE_TYPES,
  usageQuotasHelpPaths,
  storageTypeHelpPaths,
} from '../../constants';
import { getStorageTypesFromProjectStatistics, descendingStorageUsageSort } from '../utils';
import ProjectStorageDetail from './project_storage_detail.vue';

export default {
  name: 'ProjectStorageApp',
  components: {
    GlAlert,
    GlButton,
    GlLink,
    GlLoadingIcon,
    ProjectStorageDetail,
    SectionedPercentageBar,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectPath'],
  apollo: {
    project: {
      query() {
        return this.glFeatures?.displayCostFactoredStorageSizeOnProjectPages
          ? getCostFactoredProjectStorageStatistics
          : getProjectStorageStatistics;
      },
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      error() {
        this.error = s__(
          'UsageQuota|Something went wrong while fetching project storage statistics',
        );
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
        return numberToHumanSize(this.project?.statistics?.storageSize, 1, getPreferredLocales());
      }

      return __('Not applicable.');
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

    sections() {
      if (!this.project?.statistics) {
        return null;
      }

      const {
        buildArtifactsSize,
        lfsObjectsSize,
        packagesSize,
        repositorySize,
        storageSize,
        wikiSize,
        snippetsSize,
      } = this.project.statistics;

      if (storageSize === 0) {
        return null;
      }

      return [
        {
          id: 'repository',
          value: repositorySize,
        },
        {
          id: 'lfsObjects',
          value: lfsObjectsSize,
        },
        {
          id: 'packages',
          value: packagesSize,
        },
        {
          id: 'buildArtifacts',
          value: buildArtifactsSize,
        },
        {
          id: 'wiki',
          value: wikiSize,
        },
        {
          id: 'snippets',
          value: snippetsSize,
        },
      ]
        .filter((data) => data.value !== 0)
        .sort(descendingStorageUsageSort('value'))
        .map((storageType) => {
          const storageTypeExtraData = PROJECT_STORAGE_TYPES.find(
            (type) => storageType.id === type.id,
          );
          const label = storageTypeExtraData?.name;

          return {
            label,
            formattedValue: numberToHumanSize(storageType.value),
            ...storageType,
          };
        });
    },
  },
  methods: {
    clearError() {
      this.error = '';
    },
    helpLinkAriaLabel(linkTitle) {
      return sprintf(s__('UsageQuota|%{linkTitle} help link'), {
        linkTitle,
      });
    },
    async postRecalculateSize() {
      const alertEl = document.querySelector('.js-recalculation-started-alert');

      this.loadingRecalculateSize = true;

      await updateRepositorySize(this.projectPath);

      this.loadingRecalculateSize = false;
      alertEl?.classList.remove('gl-hidden');
    },
  },
  usageQuotasHelpPaths,
};
</script>
<template>
  <gl-loading-icon v-if="$apollo.queries.project.loading" class="gl-mt-5" size="lg" />
  <gl-alert v-else-if="error" variant="danger" @dismiss="clearError">
    {{ error }}
  </gl-alert>
  <div v-else>
    <div class="gl-pt-5">
      <div class="gl-flex gl-justify-between">
        <div>
          <h4 class="gl-mb-3 gl-mt-0 gl-text-lg">{{ s__('UsageQuota|Usage breakdown') }}</h4>
          <p>
            {{ s__('UsageQuota|Includes artifacts, repositories, wiki, and other items.') }}
            <gl-link
              :href="$options.usageQuotasHelpPaths.usageQuotas"
              target="_blank"
              :aria-label="helpLinkAriaLabel(s__('UsageQuota|Usage Quotas'))"
              >{{ __('Learn more.') }}</gl-link
            >
          </p>
        </div>
        <p
          class="gl-m-0 gl-whitespace-nowrap gl-text-size-h-display gl-font-bold"
          data-testid="total-usage"
        >
          {{ totalUsage }}
        </p>
      </div>
    </div>
    <div v-if="!isStatisticsEmpty" class="gl-w-full">
      <sectioned-percentage-bar class="gl-mt-5" :sections="sections" />
    </div>
    <div class="gl-my-5 gl-w-full">
      <gl-button
        :loading="loadingRecalculateSize"
        category="secondary"
        @click="postRecalculateSize"
      >
        {{ s__('UsageQuota|Recalculate repository usage') }}
      </gl-button>
    </div>
    <project-storage-detail
      :storage-types="projectStorageTypes"
      data-testid="usage-quotas-project-usage-details"
    />
    <div>
      <h2 class="gl-mb-2 gl-mt-5 gl-text-lg gl-font-bold">
        {{ s__('UsageQuota|Namespace entities') }}
      </h2>

      <project-storage-detail
        :storage-types="namespaceStorageTypes"
        data-testid="usage-quotas-namespace-usage-details"
      />
    </div>
  </div>
</template>
