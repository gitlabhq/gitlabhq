<script>
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import { ciCatalogResourcesItemsCount } from '~/ci/catalog/graphql/settings';
import CatalogSearch from '../list/catalog_search.vue';
import CiResourcesList from '../list/ci_resources_list.vue';
import CatalogListSkeletonLoader from '../list/catalog_list_skeleton_loader.vue';
import CatalogHeader from '../list/catalog_header.vue';
import EmptyState from '../list/empty_state.vue';
import getCatalogResources from '../../graphql/queries/get_ci_catalog_resources.query.graphql';
import getCurrentPage from '../../graphql/queries/client/get_current_page.query.graphql';
import updateCurrentPageMutation from '../../graphql/mutations/client/update_current_page.mutation.graphql';

export default {
  components: {
    CatalogHeader,
    CatalogListSkeletonLoader,
    CatalogSearch,
    CiResourcesList,
    EmptyState,
  },
  data() {
    return {
      catalogResources: [],
      currentPage: 1,
      pageInfo: {},
      searchTerm: '',
      totalCount: 0,
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
    currentPage: {
      query: getCurrentPage,
      update(data) {
        return data?.page?.current || 1;
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
    isSearching() {
      return this.searchTerm?.length > 0;
    },
    showEmptyState() {
      return !this.hasResources && !this.isSearching;
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

        this.decrementPage();
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

        this.incrementPage();
      } catch (e) {
        // Ensure that the current query is properly stoped if an error occurs.
        this.$apollo.queries.catalogResources.stop();

        createAlert({ message: e?.message || this.$options.i18n.fetchError, variant: 'danger' });
      }
    },
    updatePageCount(pageNumber) {
      this.$apollo.mutate({
        mutation: updateCurrentPageMutation,
        variables: {
          pageNumber,
        },
      });
    },
    decrementPage() {
      this.updatePageCount(this.currentPage - 1);
    },
    incrementPage() {
      this.updatePageCount(this.currentPage + 1);
    },
    onUpdateSearchTerm(searchTerm) {
      this.searchTerm = !searchTerm.length ? null : searchTerm;
      this.resetPageCount();
      this.$apollo.queries.catalogResources.refetch({
        searchTerm: this.searchTerm,
      });
    },
    onUpdateSorting(sortValue) {
      this.resetPageCount();
      this.$apollo.queries.catalogResources.refetch({
        sortValue,
      });
    },
    resetPageCount() {
      this.updatePageCount(1);
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
    <catalog-search
      class="gl-py-4 gl-border-b-1 gl-border-gray-100 gl-border-b-solid gl-border-t-1 gl-border-t-solid"
      @update-search-term="onUpdateSearchTerm"
      @update-sorting="onUpdateSorting"
    />
    <catalog-list-skeleton-loader v-if="isLoading" class="gl-w-full gl-mt-3" />
    <empty-state v-else-if="!hasResources" :search-term="searchTerm" />
    <template v-else>
      <ci-resources-list
        :current-page="currentPage"
        :page-info="pageInfo"
        :prev-text="__('Prev')"
        :next-text="__('Next')"
        :resources="catalogResources"
        :total-count="totalCount"
        @onPrevPage="handlePrevPage"
        @onNextPage="handleNextPage"
      />
    </template>
  </div>
</template>
