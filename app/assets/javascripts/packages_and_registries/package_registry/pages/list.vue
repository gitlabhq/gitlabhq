<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlEmptyState, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { createAlert, VARIANT_INFO } from '~/alert';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { fetchPolicies } from '~/lib/graphql';
import { historyReplaceState } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { SHOW_DELETE_SUCCESS_ALERT } from '~/packages_and_registries/shared/constants';
import {
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
import PersistedPagination from '~/packages_and_registries/shared/components/persisted_pagination.vue';
import {
  getPageParams,
  getNextPageParams,
  getPreviousPageParams,
} from '~/packages_and_registries/package_registry/utils';

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlLink,
    GlSprintf,
    PackageList,
    PackageTitle,
    PackageSearch,
    PersistedPagination,
    DeletePackages,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['emptyListIllustration', 'isGroupPage', 'fullPath', 'settingsPath'],
  data() {
    return {
      packagesResource: {},
      sort: '',
      filters: {},
      isDeleteInProgress: false,
      pageParams: {},
    };
  },
  apollo: {
    packagesResource: {
      query: getPackagesQuery,
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data[this.graphqlResource] ?? {};
      },
      skip() {
        return !this.sort;
      },
    },
  },
  computed: {
    packages() {
      return this.packagesResource?.packages ?? {};
    },
    groupSettings() {
      return this.isGroupPage
        ? this.packagesResource?.packageSettings ?? {}
        : this.packagesResource?.group?.packageSettings ?? {};
    },
    queryVariables() {
      return {
        isGroupPage: this.isGroupPage,
        fullPath: this.fullPath,
        sort: this.isGroupPage ? undefined : this.sort,
        groupSort: this.isGroupPage ? this.sort : undefined,
        packageName: this.filters?.packageName,
        packageType: this.filters?.packageType,
        packageVersion: this.filters?.packageVersion,
        first: GRAPHQL_PAGE_SIZE,
        ...this.pageParams,
      };
    },
    graphqlResource() {
      return this.isGroupPage ? WORKSPACE_GROUP : WORKSPACE_PROJECT;
    },
    pageInfo() {
      return this.packages?.pageInfo ?? {};
    },
    packagesCount() {
      return this.packages?.count;
    },
    hasFilters() {
      return this.filters.packageName || this.filters.packageType || this.filters.packageVersion;
    },
    emptySearch() {
      return !this.filters.packageName && !this.filters.packageType && !this.filters.packageVersion;
    },
    emptyStateTitle() {
      return this.emptySearch
        ? this.$options.i18n.emptyPageTitle
        : this.$options.i18n.noResultsTitle;
    },
    isLoading() {
      return this.$apollo.queries.packagesResource.loading || this.isDeleteInProgress;
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
        createAlert({ message: DELETE_PACKAGE_SUCCESS_MESSAGE, variant: VARIANT_INFO });
        const cleanUrl = window.location.href.split('?')[0];
        historyReplaceState(cleanUrl);
      }
    },
    handleSearchUpdate({ sort, filters, pageInfo }) {
      this.pageParams = getPageParams(pageInfo);
      this.sort = sort;
      this.filters = { ...filters };
    },
    fetchNextPage() {
      this.pageParams = getNextPageParams(this.pageInfo.endCursor);
    },
    fetchPreviousPage() {
      this.pageParams = getPreviousPageParams(this.pageInfo.startCursor);
    },
  },
  i18n: {
    widenFilters: s__('PackageRegistry|To widen your search, change or remove the filters above.'),
    emptyPageTitle: s__('PackageRegistry|There are no packages yet'),
    noResultsTitle: s__('PackageRegistry|Sorry, your filter produced no results'),
    noResultsText: s__(
      'PackageRegistry|Learn how to %{noPackagesLinkStart}publish and share your packages%{noPackagesLinkEnd} with GitLab.',
    ),
    settingsText: s__('PackageRegistry|Configure in settings'),
  },
  links: {
    EMPTY_LIST_HELP_URL,
    PACKAGE_HELP_URL,
  },
};
</script>

<template>
  <div>
    <package-title :help-url="$options.links.PACKAGE_HELP_URL" :count="packagesCount">
      <template v-if="settingsPath" #settings-link>
        <gl-button
          v-gl-tooltip="$options.i18n.settingsText"
          icon="settings"
          :href="settingsPath"
          :aria-label="$options.i18n.settingsText"
        />
      </template>
    </package-title>
    <package-search @update="handleSearchUpdate" />

    <delete-packages
      :refetch-queries="refetchQueriesData"
      show-success-alert
      @start="isDeleteInProgress = true"
      @end="isDeleteInProgress = false"
    >
      <template #default="{ deletePackages }">
        <package-list
          :group-settings="groupSettings"
          :list="packages.nodes"
          :is-loading="isLoading"
          @delete="deletePackages"
        >
          <template #empty-state>
            <gl-empty-state
              :title="emptyStateTitle"
              :svg-path="emptyListIllustration"
              :svg-height="150"
            >
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
    <div v-if="!isDeleteInProgress" class="gl-display-flex gl-justify-content-center">
      <persisted-pagination
        class="gl-mt-3"
        :pagination="pageInfo"
        @prev="fetchPreviousPage"
        @next="fetchNextPage"
      />
    </div>
  </div>
</template>
