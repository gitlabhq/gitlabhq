<script>
/*
 * The following component has several commented lines, this is because we are refactoring them piece by piece on several mrs
 * For a complete overview of the plan please check: https://gitlab.com/gitlab-org/gitlab/-/issues/330846
 * This work is behind feature flag: https://gitlab.com/gitlab-org/gitlab/-/issues/341136
 */
// import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import createFlash from '~/flash';
import { historyReplaceState } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { DELETE_PACKAGE_SUCCESS_MESSAGE } from '~/packages/list/constants';
import { SHOW_DELETE_SUCCESS_ALERT } from '~/packages/shared/constants';
import { FILTERED_SEARCH_TERM } from '~/packages_and_registries/shared/constants';
import { getQueryParams, extractFilterAndSorting } from '~/packages_and_registries/shared/utils';
import PackageTitle from './package_title.vue';
// import PackageSearch from './package_search.vue';
// import PackageList from './packages_list.vue';

export default {
  components: {
    // GlEmptyState,
    // GlLink,
    // GlSprintf,
    // PackageList,
    PackageTitle,
    // PackageSearch,
  },
  inject: ['packageHelpUrl', 'emptyListIllustration', 'emptyListHelpUrl'],
  data() {
    return {
      filter: [],
      sorting: {
        sort: 'desc',
        orderBy: 'created_at',
      },
      selectedType: '',
      pagination: {},
    };
  },
  computed: {
    packagesCount() {
      return 0;
    },
    emptySearch() {
      return (
        this.filter.filter((f) => f.type !== FILTERED_SEARCH_TERM || f.value?.data).length === 0
      );
    },
    emptyStateTitle() {
      return this.emptySearch
        ? this.$options.i18n.emptyPageTitle
        : this.$options.i18n.noResultsTitle;
    },
  },
  mounted() {
    const queryParams = getQueryParams(window.document.location.search);
    const { sorting, filters } = extractFilterAndSorting(queryParams);
    this.sorting = { ...sorting };
    this.filter = [...filters];
    this.checkDeleteAlert();
  },
  methods: {
    onPageChanged(page) {
      return this.requestPackagesList({ page });
    },
    onPackageDeleteRequest(item) {
      return this.requestDeletePackage(item);
    },
    checkDeleteAlert() {
      const urlParams = new URLSearchParams(window.location.search);
      const showAlert = urlParams.get(SHOW_DELETE_SUCCESS_ALERT);
      if (showAlert) {
        // to be refactored to use gl-alert
        createFlash({ message: DELETE_PACKAGE_SUCCESS_MESSAGE, type: 'notice' });
        const cleanUrl = window.location.href.split('?')[0];
        historyReplaceState(cleanUrl);
      }
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
};
</script>

<template>
  <div>
    <package-title :help-url="packageHelpUrl" :count="packagesCount" />
    <!-- <package-search @update="requestPackagesList" />

    <package-list @page:changed="onPageChanged" @package:delete="onPackageDeleteRequest">
      <template #empty-state>
        <gl-empty-state :title="emptyStateTitle" :svg-path="emptyListIllustration">
          <template #description>
            <gl-sprintf v-if="!emptySearch" :message="$options.i18n.widenFilters" />
            <gl-sprintf v-else :message="$options.i18n.noResultsText">
              <template #noPackagesLink="{ content }">
                <gl-link :href="emptyListHelpUrl" target="_blank">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </template>
        </gl-empty-state>
      </template>
    </package-list> -->
  </div>
</template>
