<script>
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import { ciCatalogResourcesItemsCount } from '~/ci/catalog/graphql/settings';
import { historyPushState } from '~/lib/utils/common_utils';
import { setUrlParams, getParameterByName } from '~/lib/utils/url_utility';
import CatalogSearch from '../list/catalog_search.vue';
import CatalogTabs from '../list/catalog_tabs.vue';
import CiResourcesList from '../list/ci_resources_list.vue';
import CatalogListSkeletonLoader from '../list/catalog_list_skeleton_loader.vue';
import CatalogHeader from '../list/catalog_header.vue';
import EmptyState from '../list/empty_state.vue';
import getCatalogResources from '../../graphql/queries/get_ci_catalog_resources.query.graphql';
import getCurrentPage from '../../graphql/queries/client/get_current_page.query.graphql';
import updateCurrentPageMutation from '../../graphql/mutations/client/update_current_page.mutation.graphql';
import getCatalogResourcesCount from '../../graphql/queries/get_ci_catalog_resources_count.query.graphql';
import { DEFAULT_SORT_VALUE, SCOPE } from '../../constants';

export default {
  i18n: {
    fetchError: s__('CiCatalog|There was an error fetching CI/CD Catalog projects.'),
    countFetchError: s__('CiCatalog|There was an error fetching the CI/CD Catalog project count.'),
  },
  components: {
    CatalogHeader,
    CatalogListSkeletonLoader,
    CatalogSearch,
    CatalogTabs,
    CiResourcesList,
    EmptyState,
  },
  data() {
    const searchTerm = getParameterByName('search');

    return {
      catalogResources: [],
      catalogResourcesCount: { all: 0, namespaces: 0 },
      currentPage: 1,
      pageInfo: {},
      scope: SCOPE.all,
      searchTerm,
      sortValue: DEFAULT_SORT_VALUE,
    };
  },
  apollo: {
    catalogResourcesCount: {
      query: getCatalogResourcesCount,
      variables() {
        return {
          searchTerm: this.searchTerm,
        };
      },
      update({ namespaces, all }) {
        return {
          namespaces: namespaces.count,
          all: all.count,
        };
      },
      error(e) {
        createAlert({
          message: e.message || this.$options.i18n.countFetchError,
        });
      },
    },
    catalogResources: {
      query: getCatalogResources,
      variables() {
        return {
          scope: this.scope,
          searchTerm: this.searchTerm,
          sortValue: this.sortValue,
          first: ciCatalogResourcesItemsCount,
        };
      },
      update(data) {
        return data?.ciCatalogResources?.nodes || [];
      },
      result({ data }) {
        const { pageInfo } = data?.ciCatalogResources || {};
        this.pageInfo = pageInfo;
      },
      error(e) {
        createAlert({ message: e.message || this.$options.i18n.fetchError });
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
    isLoadingCounts() {
      return this.$apollo.queries.catalogResourcesCount.loading;
    },
    namespacesCount() {
      return this.catalogResourcesCount.namespaces;
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
    handleSetScope(scope) {
      if (this.scope === scope) return;

      this.scope = scope;
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

      historyPushState(setUrlParams({ search: this.searchTerm }));
    },
    onUpdateSorting(sortValue) {
      this.sortValue = sortValue;
      this.resetPageCount();
    },
    resetPageCount() {
      this.updatePageCount(1);
    },
  },
};
</script>
<template>
  <div>
    <catalog-header />
    <catalog-tabs
      :is-loading="isLoadingCounts"
      :resource-counts="catalogResourcesCount"
      @setScope="handleSetScope"
    />
    <catalog-search
      :initial-search-term="searchTerm"
      @update-search-term="onUpdateSearchTerm"
      @update-sorting="onUpdateSorting"
    />
    <catalog-list-skeleton-loader v-if="isLoading" class="gl-mt-3 gl-w-full" />
    <empty-state v-else-if="!hasResources" :search-term="searchTerm" />
    <template v-else>
      <ci-resources-list
        :current-page="currentPage"
        :page-info="pageInfo"
        :prev-text="__('Prev')"
        :next-text="__('Next')"
        :resources="catalogResources"
        @onPrevPage="handlePrevPage"
        @onNextPage="handleNextPage"
      />
    </template>
  </div>
</template>
