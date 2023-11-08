<script>
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import CatalogHeader from '~/ci/catalog/components/list/catalog_header.vue';
import CatalogListSkeletonLoader from '~/ci/catalog/components/list/catalog_list_skeleton_loader.vue';
import CiResourcesList from '~/ci/catalog/components/list/ci_resources_list.vue';
import EmptyState from '~/ci/catalog/components/list/empty_state.vue';
import { ciCatalogResourcesItemsCount } from '~/ci/catalog/graphql/settings';
import getCatalogResources from '../../graphql/queries/get_ci_catalog_resources.query.graphql';

export default {
  components: {
    CatalogHeader,
    CatalogListSkeletonLoader,
    CiResourcesList,
    EmptyState,
  },
  data() {
    return {
      catalogResources: [],
      currentPage: 1,
      totalCount: 0,
      pageInfo: {},
    };
  },
  apollo: {
    catalogResources: {
      query: getCatalogResources,
      variables() {
        return {
          first: ciCatalogResourcesItemsCount,
        };
      },
      update(data) {
        return data?.ciCatalogResources?.nodes || [];
      },
      result({ data }) {
        const { pageInfo } = data?.ciCatalogResources || {};
        this.pageInfo = pageInfo;
        this.totalCount = data?.ciCatalogResources?.count || 0;
      },
      error(e) {
        createAlert({ message: e.message || this.$options.i18n.fetchError, variant: 'danger' });
      },
    },
  },
  computed: {
    hasResources() {
      return this.catalogResources.length > 0;
    },
    isLoading() {
      return this.$apollo.queries.catalogResources.loading;
    },
  },
  methods: {
    async handlePrevPage() {
      try {
        await this.$apollo.queries.catalogResources.fetchMore({
          variables: {
            before: this.pageInfo.startCursor,
            last: ciCatalogResourcesItemsCount,
            first: null,
          },
        });

        this.currentPage -= 1;
      } catch (e) {
        // Ensure that the current query is properly stoped if an error occurs.
        this.$apollo.queries.catalogResources.stop();
        createAlert({ message: e?.message || this.$options.i18n.fetchError, variant: 'danger' });
      }
    },
    async handleNextPage() {
      try {
        await this.$apollo.queries.catalogResources.fetchMore({
          variables: {
            after: this.pageInfo.endCursor,
          },
        });

        this.currentPage += 1;
      } catch (e) {
        // Ensure that the current query is properly stoped if an error occurs.
        this.$apollo.queries.catalogResources.stop();

        createAlert({ message: e?.message || this.$options.i18n.fetchError, variant: 'danger' });
      }
    },
  },
  i18n: {
    fetchError: s__('CiCatalog|There was an error fetching CI/CD Catalog resources.'),
  },
};
</script>
<template>
  <div>
    <catalog-header />
    <catalog-list-skeleton-loader v-if="isLoading" class="gl-w-full gl-mt-3" />
    <empty-state v-else-if="!hasResources" />
    <ci-resources-list
      v-else
      :current-page="currentPage"
      :page-info="pageInfo"
      :prev-text="__('Prev')"
      :next-text="__('Next')"
      :resources="catalogResources"
      :total-count="totalCount"
      @onPrevPage="handlePrevPage"
      @onNextPage="handleNextPage"
    />
  </div>
</template>
