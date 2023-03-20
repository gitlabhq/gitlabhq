<script>
import { mapState, mapGetters } from 'vuex';
import ScopeNavigation from '~/search/sidebar/components/scope_navigation.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { SCOPE_ISSUES, SCOPE_MERGE_REQUESTS, SCOPE_BLOB } from '../constants';
import ResultsFilters from './results_filters.vue';
import LanguageFilter from './language_filter/index.vue';

export default {
  name: 'GlobalSearchSidebar',
  components: {
    ResultsFilters,
    ScopeNavigation,
    LanguageFilter,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapState(['urlQuery']),
    ...mapGetters(['currentScope']),
    showIssueAndMergeFilters() {
      return this.currentScope === SCOPE_ISSUES || this.currentScope === SCOPE_MERGE_REQUESTS;
    },
    showBlobFilter() {
      return this.currentScope === SCOPE_BLOB;
    },
  },
};
</script>

<template>
  <section
    class="search-sidebar gl-display-flex gl-flex-direction-column gl-md-mr-5 gl-mb-6 gl-mt-5"
  >
    <scope-navigation />
    <results-filters v-if="showIssueAndMergeFilters" />
    <language-filter v-if="showBlobFilter" />
  </section>
</template>
