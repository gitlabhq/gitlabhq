<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import getCatalogCiResourceSharedData from '../../graphql/queries/get_ci_catalog_resource_shared_data.query.graphql';
import CiResourceDetails from '../details/ci_resource_details.vue';
import CiResourceHeader from '../details/ci_resource_header.vue';

export default {
  components: {
    CiResourceDetails,
    CiResourceHeader,
    GlEmptyState,
  },
  inject: ['ciCatalogPath'],
  data() {
    return {
      isEmpty: false,
      resourceSharedData: {},
    };
  },
  apollo: {
    resourceSharedData: {
      query: getCatalogCiResourceSharedData,
      variables() {
        return {
          fullPath: this.cleanFullPath,
        };
      },
      update(data) {
        return data.ciCatalogResource;
      },
      error(e) {
        this.isEmpty = true;
        createAlert({ message: e.message });
      },
    },
  },
  computed: {
    cleanFullPath() {
      return cleanLeadingSeparator(this.$route.params.id);
    },
    isLoadingData() {
      return this.$apollo.queries.resourceSharedData.loading;
    },
    version() {
      return this.resourceSharedData?.versions?.nodes[0]?.name || '';
    },
  },
  i18n: {
    emptyStateTitle: s__('CiCatalog|No component available'),
    emptyStateDescription: s__(
      'CiCatalog|Component ID not found, or you do not have permission to access component.',
    ),
    emptyStateButtonText: s__('CiCatalog|Back to the CI/CD Catalog'),
  },
};
</script>
<template>
  <div>
    <div v-if="isEmpty" class="gl-display-flex">
      <gl-empty-state
        :title="$options.i18n.emptyStateTitle"
        :description="$options.i18n.emptyStateDescription"
        :primary-button-text="$options.i18n.emptyStateButtonText"
        :primary-button-link="ciCatalogPath"
      />
    </div>
    <div v-else>
      <ci-resource-header :is-loading-data="isLoadingData" :resource="resourceSharedData" />
      <ci-resource-details :resource-path="cleanFullPath" :version="version" />
    </div>
  </div>
</template>
