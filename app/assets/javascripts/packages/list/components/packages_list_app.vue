<script>
import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import createFlash from '~/flash';
import { historyReplaceState } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { SHOW_DELETE_SUCCESS_ALERT } from '~/packages/shared/constants';
import { FILTERED_SEARCH_TERM } from '~/packages_and_registries/shared/constants';
import { DELETE_PACKAGE_SUCCESS_MESSAGE } from '../constants';
import PackageSearch from './package_search.vue';
import PackageTitle from './package_title.vue';
import PackageList from './packages_list.vue';

export default {
  components: {
    GlEmptyState,
    GlLink,
    GlSprintf,
    PackageList,
    PackageTitle,
    PackageSearch,
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
        ? s__('PackageRegistry|There are no packages yet')
        : s__('PackageRegistry|Sorry, your filter produced no results');
    },
  },
  mounted() {
    this.requestPackagesList();
    this.checkDeleteAlert();
  },
  methods: {
    ...mapActions(['requestPackagesList', 'requestDeletePackage', 'setSelectedType']),
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
    noResults: s__(
      'PackageRegistry|Learn how to %{noPackagesLinkStart}publish and share your packages%{noPackagesLinkEnd} with GitLab.',
    ),
  },
};
</script>

<template>
  <div>
    <package-title :package-help-url="packageHelpUrl" :packages-count="packagesCount" />
    <package-search @update="requestPackagesList" />

    <package-list @page:changed="onPageChanged" @package:delete="onPackageDeleteRequest">
      <template #empty-state>
        <gl-empty-state :title="emptyStateTitle" :svg-path="emptyListIllustration">
          <template #description>
            <gl-sprintf v-if="!emptySearch" :message="$options.i18n.widenFilters" />
            <gl-sprintf v-else :message="$options.i18n.noResults">
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
