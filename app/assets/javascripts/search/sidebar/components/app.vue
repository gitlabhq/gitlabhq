<script>
import { mapState, mapGetters } from 'vuex';
import ScopeLegacyNavigation from '~/search/sidebar/components/scope_legacy_navigation.vue';
import ScopeSidebarNavigation from '~/search/sidebar/components/scope_sidebar_navigation.vue';
import SidebarPortal from '~/super_sidebar/components/sidebar_portal.vue';
import { SCOPE_ISSUES, SCOPE_MERGE_REQUESTS, SCOPE_BLOB } from '../constants';
import ResultsFilters from './results_filters.vue';
import LanguageFilter from './language_filter/index.vue';

export default {
  name: 'GlobalSearchSidebar',
  components: {
    ResultsFilters,
    ScopeLegacyNavigation,
    ScopeSidebarNavigation,
    LanguageFilter,
    SidebarPortal,
  },
  computed: {
    // useSidebarNavigation refers to whether the new left sidebar navigation is enabled
    ...mapState(['useSidebarNavigation']),
    ...mapGetters(['currentScope']),
    showIssueAndMergeFilters() {
      return this.currentScope === SCOPE_ISSUES || this.currentScope === SCOPE_MERGE_REQUESTS;
    },
    showBlobFilter() {
      return this.currentScope === SCOPE_BLOB;
    },
    showScopeNavigation() {
      // showLegacyNavigation refers to whether the scope navigation should be shown
      // while the legacy navigation is being used and there are no search results the scope navigation has to be hidden
      return Boolean(this.currentScope);
    },
  },
};
</script>

<template>
  <section v-if="useSidebarNavigation">
    <sidebar-portal>
      <scope-sidebar-navigation />
      <results-filters v-if="showIssueAndMergeFilters" />
      <language-filter v-if="showBlobFilter" />
    </sidebar-portal>
  </section>
  <section
    v-else-if="showScopeNavigation"
    class="search-sidebar gl-display-flex gl-flex-direction-column gl-md-mr-5 gl-mb-6 gl-mt-5"
  >
    <scope-legacy-navigation />
    <results-filters v-if="showIssueAndMergeFilters" />
    <language-filter v-if="showBlobFilter" />
  </section>
</template>
