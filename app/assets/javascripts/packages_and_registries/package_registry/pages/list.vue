<script>
import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { createAlert, VARIANT_INFO } from '~/flash';
import { historyReplaceState } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { SHOW_DELETE_SUCCESS_ALERT } from '~/packages_and_registries/shared/constants';
import {
  PROJECT_RESOURCE_TYPE,
  GROUP_RESOURCE_TYPE,
  GRAPHQL_PAGE_SIZE,
  DELETE_PACKAGE_SUCCESS_MESSAGE,
  EMPTY_LIST_HELP_URL,
  PACKAGE_HELP_URL,
} from '~/packages_and_registries/package_registry/constants';
import getPackagesQuery from '~/packages_and_registries/package_registry/graphql/queries/get_packages.query.graphql';
import DeletePackages from '~/packages_and_registries/package_registry/components/functional/delete_packages.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/list/package_title.vue';
import PackageSearch from '~/packages_and_registries/package_registry/components/list/package_search.vue';
import PackageList from '~/packages_and_registries/package_registry/components/list/packages_list.vue';

export default {
  components: {
    GlEmptyState,
    GlLink,
    GlSprintf,
    PackageList,
    PackageTitle,
    PackageSearch,
    DeletePackages,
  },
  inject: ['emptyListIllustration', 'isGroupPage', 'fullPath'],
  data() {
    return {
      packages: {},
      sort: '',
      filters: {},
      mutationLoading: false,
    };
  },
  apollo: {
    packages: {
      query: getPackagesQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data[this.graphqlResource].packages;
      },
      skip() {
        return !this.sort;
      },
    },
  },
  computed: {
    queryVariables() {
      return {
        isGroupPage: this.isGroupPage,
        fullPath: this.fullPath,
        sort: this.isGroupPage ? undefined : this.sort,
        groupSort: this.isGroupPage ? this.sort : undefined,
        packageName: this.filters?.packageName,
        packageType: this.filters?.packageType,
        first: GRAPHQL_PAGE_SIZE,
      };
    },
    graphqlResource() {
      return this.isGroupPage ? GROUP_RESOURCE_TYPE : PROJECT_RESOURCE_TYPE;
    },
    pageInfo() {
      return this.packages?.pageInfo ?? {};
    },
    packagesCount() {
      return this.packages?.count;
    },
    hasFilters() {
      return this.filters.packageName && this.filters.packageType;
    },
    emptySearch() {
      return !this.filters.packageName && !this.filters.packageType;
    },
    emptyStateTitle() {
      return this.emptySearch
        ? this.$options.i18n.emptyPageTitle
        : this.$options.i18n.noResultsTitle;
    },
    isLoading() {
      return this.$apollo.queries.packages.loading || this.mutationLoading;
    },
    refetchQueriesData() {
      return [
        {
          query: getPackagesQuery,
          variables: this.queryVariables,
        },
      ];
    },
  },
  mounted() {
    this.checkDeleteAlert();
  },
  methods: {
    checkDeleteAlert() {
      const urlParams = new URLSearchParams(window.location.search);
      const showAlert = urlParams.get(SHOW_DELETE_SUCCESS_ALERT);
      if (showAlert) {
        // to be refactored to use gl-alert
        createAlert({ message: DELETE_PACKAGE_SUCCESS_MESSAGE, variant: VARIANT_INFO });
        const cleanUrl = window.location.href.split('?')[0];
        historyReplaceState(cleanUrl);
      }
    },
    handleSearchUpdate({ sort, filters }) {
      this.sort = sort;
      this.filters = { ...filters };
    },
    updateQuery(_, { fetchMoreResult }) {
      return fetchMoreResult;
    },
    fetchNextPage() {
      const variables = {
        ...this.queryVariables,
        first: GRAPHQL_PAGE_SIZE,
        last: null,
        after: this.pageInfo?.endCursor,
      };

      this.$apollo.queries.packages.fetchMore({
        variables,
        updateQuery: this.updateQuery,
      });
    },
    fetchPreviousPage() {
      const variables = {
        ...this.queryVariables,
        first: null,
        last: GRAPHQL_PAGE_SIZE,
        before: this.pageInfo?.startCursor,
      };

      this.$apollo.queries.packages.fetchMore({
        variables,
        updateQuery: this.updateQuery,
      });
    },
  },
  i18n: {
    widenFilters: s__('PackageRegistry|To widen your search, change or remove the filters above.'),
    emptyPageTitle: s__('PackageRegistry|There are no packages yet'),
    noResultsTitle: s__('PackageRegistry|Sorry, your filter produced no results'),
    noResultsText: s__(
      'PackageRegistry|Learn how to %{noPackagesLinkStart}publish and share your packages%{noPackagesLinkEnd} with GitLab.',
    ),
  },
  links: {
    EMPTY_LIST_HELP_URL,
    PACKAGE_HELP_URL,
  },
};
</script>

<template>
  <div>
    <package-title :help-url="$options.links.PACKAGE_HELP_URL" :count="packagesCount" />
    <package-search class="gl-mb-5" @update="handleSearchUpdate" />

    <delete-packages
      :refetch-queries="refetchQueriesData"
      show-success-alert
      @start="mutationLoading = true"
      @end="mutationLoading = false"
    >
      <template #default="{ deletePackages }">
        <package-list
          :list="packages.nodes"
          :is-loading="isLoading"
          :page-info="pageInfo"
          @prev-page="fetchPreviousPage"
          @next-page="fetchNextPage"
          @delete="deletePackages"
        >
          <template #empty-state>
            <gl-empty-state :title="emptyStateTitle" :svg-path="emptyListIllustration">
              <template #description>
                <gl-sprintf v-if="hasFilters" :message="$options.i18n.widenFilters" />
                <gl-sprintf v-else :message="$options.i18n.noResultsText">
                  <template #noPackagesLink="{ content }">
                    <gl-link :href="$options.links.EMPTY_LIST_HELP_URL" target="_blank">{{
                      content
                    }}</gl-link>
                  </template>
                </gl-sprintf>
              </template>
            </gl-empty-state>
          </template>
        </package-list>
      </template>
    </delete-packages>
  </div>
</template>
