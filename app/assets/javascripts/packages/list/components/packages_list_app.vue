<script>
import { mapActions, mapState } from 'vuex';
import { GlEmptyState, GlTab, GlTabs, GlLink, GlSprintf } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import createFlash from '~/flash';
import { historyReplaceState } from '~/lib/utils/common_utils';
import { SHOW_DELETE_SUCCESS_ALERT } from '~/packages/shared/constants';
import PackageFilter from './packages_filter.vue';
import PackageList from './packages_list.vue';
import PackageSort from './packages_sort.vue';
import { PACKAGE_REGISTRY_TABS, DELETE_PACKAGE_SUCCESS_MESSAGE } from '../constants';
import PackageTitle from './package_title.vue';

export default {
  components: {
    GlEmptyState,
    GlTab,
    GlTabs,
    GlLink,
    GlSprintf,
    PackageFilter,
    PackageList,
    PackageSort,
    PackageTitle,
  },
  computed: {
    ...mapState({
      emptyListIllustration: state => state.config.emptyListIllustration,
      emptyListHelpUrl: state => state.config.emptyListHelpUrl,
      filterQuery: state => state.filterQuery,
      selectedType: state => state.selectedType,
      packageHelpUrl: state => state.config.packageHelpUrl,
      packagesCount: state => state.pagination?.total,
    }),
    tabsToRender() {
      return PACKAGE_REGISTRY_TABS;
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
    tabChanged(index) {
      const selected = PACKAGE_REGISTRY_TABS[index];

      if (selected !== this.selectedType) {
        this.setSelectedType(selected);
        this.requestPackagesList();
      }
    },
    emptyStateTitle({ title, type }) {
      if (this.filterQuery) {
        return s__('PackageRegistry|Sorry, your filter produced no results');
      }

      if (type) {
        return sprintf(s__('PackageRegistry|There are no %{packageType} packages yet'), {
          packageType: title,
        });
      }

      return s__('PackageRegistry|There are no packages yet');
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

    <gl-tabs @input="tabChanged">
      <template #tabs-end>
        <div
          class="gl-display-flex gl-align-self-center gl-py-2 gl-flex-grow-1 gl-justify-content-end"
        >
          <package-filter class="gl-mr-2" @filter="requestPackagesList" />
          <package-sort @sort:changed="requestPackagesList" />
        </div>
      </template>

      <gl-tab v-for="(tab, index) in tabsToRender" :key="index" :title="tab.title">
        <package-list @page:changed="onPageChanged" @package:delete="onPackageDeleteRequest">
          <template #empty-state>
            <gl-empty-state :title="emptyStateTitle(tab)" :svg-path="emptyListIllustration">
              <template #description>
                <gl-sprintf v-if="filterQuery" :message="$options.i18n.widenFilters" />
                <gl-sprintf v-else :message="$options.i18n.noResults">
                  <template #noPackagesLink="{content}">
                    <gl-link :href="emptyListHelpUrl" target="_blank">{{ content }}</gl-link>
                  </template>
                </gl-sprintf>
              </template>
            </gl-empty-state>
          </template>
        </package-list>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
