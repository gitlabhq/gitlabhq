<script>
import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { createAlert, VARIANT_INFO } from '~/alert';
import { historyReplaceState } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { SHOW_DELETE_SUCCESS_ALERT } from '~/packages_and_registries/shared/constants';

import { getQueryParams, extractFilterAndSorting } from '~/packages_and_registries/shared/utils';
import InfrastructureTitle from '~/packages_and_registries/infrastructure_registry/list/components/infrastructure_title.vue';
import InfrastructureSearch from '~/packages_and_registries/infrastructure_registry/list/components/infrastructure_search.vue';
import PackageList from '~/packages_and_registries/infrastructure_registry/list/components/packages_list.vue';
import { DELETE_PACKAGE_SUCCESS_MESSAGE } from '~/packages_and_registries/infrastructure_registry/list/constants';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

export default {
  components: {
    GlEmptyState,
    GlLink,
    GlSprintf,
    PackageList,
    InfrastructureTitle,
    InfrastructureSearch,
  },
  inject: {
    emptyPageTitle: {
      from: 'emptyPageTitle',
      default: s__('PackageRegistry|There are no packages yet'),
    },
    noResultsText: {
      from: 'noResultsText',
      default: s__(
        'PackageRegistry|Learn how to %{noPackagesLinkStart}publish and share your packages%{noPackagesLinkEnd} with GitLab.',
      ),
    },
  },
  computed: {
    ...mapState({
      emptyListIllustration: (state) => state.config.emptyListIllustration,
      emptyListHelpUrl: (state) => state.config.emptyListHelpUrl,
      filter: (state) => state.filter,
      selectedType: (state) => state.selectedType,
      packageHelpUrl: (state) => state.config.packageHelpUrl,
      packagesCount: (state) => state.pagination?.total,
    }),
    emptySearch() {
      return (
        this.filter.filter((f) => f.type !== FILTERED_SEARCH_TERM || f.value?.data).length === 0
      );
    },

    emptyStateTitle() {
      return this.emptySearch
        ? this.emptyPageTitle
        : s__('PackageRegistry|Sorry, your filter produced no results');
    },
  },
  mounted() {
    const queryParams = getQueryParams(window.document.location.search);
    const { sorting, filters } = extractFilterAndSorting(queryParams);
    this.setSorting(sorting);
    this.setFilter(filters);
    this.requestPackagesList();
    this.checkDeleteAlert();
  },
  methods: {
    ...mapActions([
      'requestPackagesList',
      'requestDeletePackage',
      'setSelectedType',
      'setSorting',
      'setFilter',
    ]),
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
        createAlert({ message: DELETE_PACKAGE_SUCCESS_MESSAGE, variant: VARIANT_INFO });
        const cleanUrl = window.location.href.split('?')[0];
        historyReplaceState(cleanUrl);
      }
    },
  },
  i18n: {
    widenFilters: s__('PackageRegistry|To widen your search, change or remove the filters above.'),
  },
};
</script>

<template>
  <div>
    <infrastructure-title :help-url="packageHelpUrl" :count="packagesCount" />
    <infrastructure-search v-if="packagesCount > 0" @update="requestPackagesList" />

    <package-list @page:changed="onPageChanged" @package:delete="onPackageDeleteRequest">
      <template #empty-state>
        <gl-empty-state :title="emptyStateTitle" :svg-path="emptyListIllustration">
          <template #description>
            <gl-sprintf v-if="!emptySearch" :message="$options.i18n.widenFilters" />
            <gl-sprintf v-else :message="noResultsText">
              <template #noPackagesLink="{ content }">
                <gl-link :href="emptyListHelpUrl" target="_blank">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </template>
        </gl-empty-state>
      </template>
    </package-list>
  </div>
</template>
