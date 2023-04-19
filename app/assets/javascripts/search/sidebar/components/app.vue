<script>
import { mapState, mapGetters } from 'vuex';
import ScopeNavigation from '~/search/sidebar/components/scope_navigation.vue';
import ScopeNewNavigation from '~/search/sidebar/components/scope_new_navigation.vue';
import SidebarPortal from '~/super_sidebar/components/sidebar_portal.vue';
import { SCOPE_ISSUES, SCOPE_MERGE_REQUESTS, SCOPE_BLOB } from '../constants';
import ResultsFilters from './results_filters.vue';
import LanguageFilter from './language_filter/index.vue';

export default {
  name: 'GlobalSearchSidebar',
  components: {
    ResultsFilters,
    ScopeNavigation,
    ScopeNewNavigation,
    LanguageFilter,
    SidebarPortal,
  },
  computed: {
    ...mapState(['urlQuery', 'useNewNavigation']),
    ...mapGetters(['currentScope']),
    showIssueAndMergeFilters() {
      return this.currentScope === SCOPE_ISSUES || this.currentScope === SCOPE_MERGE_REQUESTS;
    },
    showBlobFilter() {
      return this.currentScope === SCOPE_BLOB;
    },
    showOldNavigation() {
      return Boolean(this.currentScope);
    },
  },
};
</script>

<template>
  <section v-if="useNewNavigation">
    <sidebar-portal>
      <scope-new-navigation />
      <results-filters v-if="showIssueAndMergeFilters" />
      <language-filter v-if="showBlobFilter" />
    </sidebar-portal>
  </section>
  <section
    v-else
    class="search-sidebar gl-display-flex gl-flex-direction-column gl-md-mr-5 gl-mb-6 gl-mt-5"
  >
    <scope-navigation />
    <results-filters v-if="showIssueAndMergeFilters" />
    <language-filter v-if="showBlobFilter" />
  </section>
</template>
