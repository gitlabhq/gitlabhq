<script>
import { GlEmptyState } from '@gitlab/ui';
import { debounce } from 'lodash-es';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import { formatDate } from '~/lib/utils/datetime_utility';
import { ISO_SHORT_FORMAT } from '~/vue_shared/constants';
import getCatalogCiResourceSharedData from '../../graphql/queries/get_ci_catalog_resource_shared_data.query.graphql';
import getCiCatalogResourceVersions from '../../graphql/queries/get_ci_catalog_resource_versions.query.graphql';
import CiResourceDetails from '../details/ci_resource_details.vue';
import CiResourceHeader from '../details/ci_resource_header.vue';

const SEARCH_DEBOUNCE_MS = 300;

export default {
  name: 'CiResourceDetailsPage',
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
      versions: [],
      initialVersionId: null,
      selectedVersion: null,
      latestVersionName: null,
      searchTerm: '',
    };
  },
  apollo: {
    versions: {
      query: getCiCatalogResourceVersions,
      variables() {
        return {
          fullPath: this.cleanFullPath,
          search: this.searchTerm,
        };
      },
      update(data) {
        const nodes = data?.ciCatalogResource?.versions?.nodes || [];
        const formatted = nodes.map((version) => ({
          value: version.id,
          text: version.name,
          createdAt: formatDate(version.createdAt, ISO_SHORT_FORMAT),
        }));

        if (formatted.length > 0 && !this.selectedVersion) {
          const versionParam = this.$route.query.version;
          const versionFromUrl = formatted.find((v) => v.text === versionParam);
          const emptyVersion =
            versionParam && !versionFromUrl ? { text: versionParam, value: '0' } : undefined;

          const versionToSelect = versionFromUrl || emptyVersion || formatted[0];

          this.initialVersionId = versionToSelect.value;
          this.selectedVersion = versionToSelect.text;
          this.latestVersionName = formatted[0].text;

          return [...formatted, emptyVersion].filter(Boolean);
        }

        return formatted;
      },
      error() {
        createAlert({ message: s__('CiCatalog|Failed to load resource versions') });
      },
    },
    resourceSharedData: {
      query: getCatalogCiResourceSharedData,
      skip() {
        return this.$apollo.queries.versions?.loading;
      },
      variables() {
        return {
          fullPath: this.cleanFullPath,
          version: this.selectedVersion,
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
      return (
        (this.$apollo.queries.versions.loading && !this.versions.length) ||
        this.$apollo.queries.resourceSharedData.loading
      );
    },
    isSearchingVersions() {
      return this.$apollo.queries.versions.loading;
    },
    version() {
      return this.selectedVersion || this.resourceSharedData?.versions?.nodes[0]?.name || '';
    },
  },
  created() {
    this.debouncedSearch = debounce((searchTerm) => {
      this.searchTerm = searchTerm;
    }, SEARCH_DEBOUNCE_MS);
  },
  beforeDestroy() {
    this.debouncedSearch?.cancel();
  },
  methods: {
    onVersionSearch(searchTerm) {
      this.debouncedSearch(searchTerm);
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
  <div v-if="isEmpty" class="gl-flex">
    <gl-empty-state
      :title="$options.i18n.emptyStateTitle"
      :description="$options.i18n.emptyStateDescription"
      :primary-button-text="$options.i18n.emptyStateButtonText"
      :primary-button-link="ciCatalogPath"
    />
  </div>
  <div v-else>
    <ci-resource-header
      :is-loading-data="isLoadingData"
      :is-searching-versions="isSearchingVersions"
      :resource="resourceSharedData"
      :versions="versions"
      :initial-version-id="initialVersionId"
      :latest-version-name="latestVersionName"
      @version-selected="selectedVersion = $event"
      @version-search="onVersionSearch"
    />
    <ci-resource-details v-if="!isLoadingData" :resource-path="cleanFullPath" :version="version" />
  </div>
</template>
