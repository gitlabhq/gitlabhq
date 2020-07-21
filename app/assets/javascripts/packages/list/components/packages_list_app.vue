<script>
import { mapActions, mapState } from 'vuex';
import { GlEmptyState, GlTab, GlTabs, GlLink, GlSprintf } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import PackageFilter from './packages_filter.vue';
import PackageList from './packages_list.vue';
import PackageSort from './packages_sort.vue';
import { PACKAGE_REGISTRY_TABS } from '../constants';
import PackagesComingSoon from '../coming_soon/packages_coming_soon.vue';

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
    PackagesComingSoon,
  },
  computed: {
    ...mapState({
      emptyListIllustration: state => state.config.emptyListIllustration,
      emptyListHelpUrl: state => state.config.emptyListHelpUrl,
      comingSoon: state => state.config.comingSoon,
      filterQuery: state => state.filterQuery,
    }),
    tabsToRender() {
      return PACKAGE_REGISTRY_TABS;
    },
  },
  mounted() {
    this.requestPackagesList();
  },
  methods: {
    ...mapActions(['requestPackagesList', 'requestDeletePackage', 'setSelectedType']),
    onPageChanged(page) {
      return this.requestPackagesList({ page });
    },
    onPackageDeleteRequest(item) {
      return this.requestDeletePackage(item);
    },
    tabChanged(e) {
      const selectedType = PACKAGE_REGISTRY_TABS[e];

      if (selectedType) {
        this.setSelectedType(selectedType);
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
  <gl-tabs @input="tabChanged">
    <template #tabs-end>
      <div class="d-flex align-self-center ml-md-auto py-1 py-md-0">
        <package-filter class="mr-1" @filter="requestPackagesList" />
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

    <gl-tab v-if="comingSoon" :title="__('Coming soon')" lazy>
      <packages-coming-soon
        :illustration="emptyListIllustration"
        :project-path="comingSoon.projectPath"
        :suggested-contributions-path="comingSoon.suggestedContributions"
      />
    </gl-tab>
  </gl-tabs>
</template>
